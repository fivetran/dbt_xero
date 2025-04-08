{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

{% set using_tracking = (
    var('xero__using_journal_line_has_tracking_category', True)
    and var('xero__using_tracking_category', True)
    and var('xero__using_tracking_category_option', True)
    and var('xero__using_tracking_category_has_option', True)
) %}

{% if using_tracking %}
    {% set tracking_cols = dbt_utils.get_filtered_columns_in_relation(
        from=ref('int_xero__journal_line_pivoted_tracking_categories'),
        except=['journal_id', 'journal_line_id', 'source_relation']
    ) %}
{% else %}
    {% set tracking_cols = [] %}
{% endif %}

with calendar as (

    select *
    from {{ ref('xero__calendar_spine') }}

), journal as (

    select *
    from {{ ref('stg_xero__journal') }}

), journal_line as (

    select *
    from {{ ref('stg_xero__journal_line') }}

), account as (

    select *
    from {{ ref('stg_xero__account') }}

){% if using_tracking %}
, pivoted_tracking_categories as (

    select *
    from {{ ref('int_xero__journal_line_pivoted_tracking_categories') }}

)
{% endif %}

, staging_profit_and_loss as (

    select
        {{ dbt.date_trunc('month', 'journal.journal_date') }} as date_month,
        journal_line.account_id,
        journal.source_relation,

        {% if using_tracking %}
        {{ dbt_utils.star(
            from=ref('int_xero__journal_line_pivoted_tracking_categories'),
            relation_alias='pivoted_tracking_categories',
            except=['journal_id', 'journal_line_id', 'source_relation']
        ) }},
        {% endif %}

        sum(journal_line.net_amount * -1) as net_amount

    from journal
    join journal_line
        on journal.journal_id = journal_line.journal_id
    join account
        on account.account_id = journal_line.account_id

    {% if using_tracking %}
    left join pivoted_tracking_categories
        on journal_line.journal_line_id = pivoted_tracking_categories.journal_line_id
        and journal.journal_id = pivoted_tracking_categories.journal_id
        and journal.source_relation = pivoted_tracking_categories.source_relation
    {% endif %}

    where account.account_class in ('REVENUE', 'EXPENSE')

    group by
        date_month,
        journal_line.account_id,
        journal.source_relation
        {% for col in tracking_cols %}, {{ col }}{% endfor %}
)

, profit_and_loss as (

    select *
    from {{ ref('xero__profit_and_loss_report') }}
)

, final as (

    select
        profit_and_loss.date_month,
        profit_and_loss.account_id,
        profit_and_loss.source_relation,

        {% for col in tracking_cols %}
            coalesce(staging_profit_and_loss.{{ col }}, profit_and_loss.{{ col }}) as {{ col }},
        {% endfor %}

        staging_profit_and_loss.net_amount as calculated_net_amount,
        profit_and_loss.net_amount as reported_net_amount,
        abs(coalesce(staging_profit_and_loss.net_amount, 0) - coalesce(profit_and_loss.net_amount, 0)) as net_difference

    from staging_profit_and_loss
    full outer join profit_and_loss
        on staging_profit_and_loss.date_month = {{ dbt.date_trunc('month', 'profit_and_loss.date_month') }}
        and staging_profit_and_loss.account_id = profit_and_loss.account_id
        and staging_profit_and_loss.source_relation = profit_and_loss.source_relation
        {% for col in tracking_cols %}
            and staging_profit_and_loss.{{ col }} = profit_and_loss.{{ col }}
        {% endfor %}
)

select *
from final
where net_difference > 0.01
