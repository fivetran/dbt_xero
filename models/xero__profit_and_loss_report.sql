{%- set pivoted_columns = dbt_utils.get_filtered_columns_in_relation(
    from=ref('int_xero__journal_line_pivoted_tracking_categories'),
    except=['journal_id', 'journal_line_id', 'source_relation']
) -%}

{%- set pivoted_columns_prefixed = [] %}
{%- for col in pivoted_columns %}
    {%- do pivoted_columns_prefixed.append('pivoted_tracking_categories.' ~ col) %}
{%- endfor %}

with calendar as (

    select *
    from {{ ref('xero__calendar_spine') }}

), ledger as (

    select *
    from {{ ref('xero__general_ledger') }}

),  pivoted_tracking_categories as (

    select *
    from {{ ref('int_xero__journal_line_pivoted_tracking_categories') }}

), joined as (

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
        {{ dbt_utils.star(
            from=ref('int_xero__journal_line_pivoted_tracking_categories'),
            relation_alias='pivoted_tracking_categories',
            except=['journal_id', 'journal_line_id', 'source_relation']
        ) }},

        coalesce(sum(ledger.net_amount * -1), 0) as net_amount

    from calendar

    left join ledger
        on calendar.date_month = cast({{ dbt.date_trunc('month', 'ledger.journal_date') }} as date)

    left join pivoted_tracking_categories
        on ledger.journal_line_id = pivoted_tracking_categories.journal_line_id
        and ledger.journal_id = pivoted_tracking_categories.journal_id
        and ledger.source_relation = pivoted_tracking_categories.source_relation

    where ledger.account_class in ('REVENUE','EXPENSE')

    group by
        calendar.date_month,
        ledger.account_id,
        ledger.account_name,
        ledger.account_code,
        ledger.account_type,
        ledger.account_class,
        ledger.source_relation,
        {{ dbt_utils.star(
            from=ref('int_xero__journal_line_pivoted_tracking_categories'),
            relation_alias='pivoted_tracking_categories',
            except=['journal_id', 'journal_line_id', 'source_relation']
        ) }}
)

select *
from joined