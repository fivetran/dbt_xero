{%- set using_tracking_categories = (
    var('xero__using_journal_line_tracking_category', True)
    and var('xero__using_tracking_categories', True)
) -%}

{% if using_tracking_categories %}
    {%- set pivoted_columns = dbt_utils.get_filtered_columns_in_relation(
        from=ref('int_xero__journal_line_pivoted_tracking_categories'),
        except=['journal_id', 'journal_line_id', 'source_relation']
    ) -%}

    {%- set pivoted_columns_prefixed = [] %}
    {%- for col in pivoted_columns %}
        {%- do pivoted_columns_prefixed.append('pivoted_tracking_categories.' ~ col) %}
    {%- endfor %}
{%- else -%}
    {%- set pivoted_columns = [] -%}
    {%- set pivoted_columns_prefixed = [] -%}
{%- endif -%}

with calendar as (

    select *
    from {{ ref('xero__calendar_spine') }}

), ledger as (

    select *
    from {{ ref('xero__general_ledger') }}

)

{% if using_tracking_categories %}
, pivoted_tracking_categories as (

    select *
    from {{ ref('int_xero__journal_line_pivoted_tracking_categories') }}

){% endif %}

, joined as (

    select 
        {{ dbt_utils.generate_surrogate_key([
            'calendar.date_month',
            'ledger.account_id',
            'ledger.source_relation'
        ] + pivoted_columns_prefixed) }} as profit_and_loss_id,
        calendar.date_month, 
        ledger.account_id,
        ledger.account_name,
        ledger.account_code,
        ledger.account_type, 
        ledger.account_class, 
        ledger.source_relation,

        -- Dynamically pivoted tracking category columns
        {% if using_tracking_categories %}
        {{ dbt_utils.star(
            from=ref('int_xero__journal_line_pivoted_tracking_categories'),
            relation_alias='pivoted_tracking_categories',
            except=['journal_id', 'journal_line_id', 'source_relation']
        ) }},
        {% endif %}
        coalesce(sum(ledger.net_amount * -1), 0) as net_amount

    from calendar

    left join ledger
        on calendar.date_month = cast({{ dbt.date_trunc('month', 'ledger.journal_date') }} as date)

    {% if using_tracking_categories %}
    left join pivoted_tracking_categories
        on ledger.journal_line_id = pivoted_tracking_categories.journal_line_id
        and ledger.journal_id = pivoted_tracking_categories.journal_id
        and ledger.source_relation = pivoted_tracking_categories.source_relation
    {% endif %}

    where ledger.account_class in ('REVENUE','EXPENSE')

    {{ dbt_utils.group_by(n=8 + pivoted_columns_prefixed|length) }}
)

select *
from joined