with calendar as (

    select *
    from {{ ref('xero__calendar_spine') }}

), ledger as (

    select *
    from {{ ref('xero__general_ledger') }}

), organization as (

    select 
        *,
        cast(extract(year from current_date) as {{ dbt.type_string() }}) as current_year,
        cast(extract(year from {{ dbt.dateadd('year', -1, 'current_date') }}) as {{ dbt.type_string() }}) as last_year
    from {{ var('organization') }}


), year_end as (

-- Calculate the current financial year-end date for each organization:
-- For February, determine last day by subtracting 1 day from March 1, avoiding leap year logic.
-- Compare the year end date to the current date:
--   Use this year's date if it's on or after the current date.
--   Otherwise, use last year's corresponding date.
    select 
        source_relation,
        case when financial_year_end_month = 2 and financial_year_end_day = 29
            then
                case when cast({{ dbt.dateadd('day', -1, "cast(current_year || '-03-01' as date)") }} as date) >= current_date
                    then cast({{ dbt.dateadd('day', -1, "cast(current_year || '-03-01' as date)") }} as date)
                    else cast({{ dbt.dateadd('day', -1, "cast(last_year || '-03-01' as date)") }} as date)
                    end
            else
                case when cast(current_year || '-' || financial_year_end_month || '-' || financial_year_end_day as date) >= current_date
                    then cast(current_year || '-' || financial_year_end_month || '-' || financial_year_end_day as date)
                    else cast(last_year || '-' || financial_year_end_month || '-' || financial_year_end_day as date)
                    end
        end as current_year_end_date

    from organization

), joined as (

    select
        calendar.date_month,
        case
            when ledger.account_class in ('ASSET','EQUITY','LIABILITY') then ledger.account_name
            when ledger.journal_date <= {{ dbt.dateadd('year', -1, 'year_end.current_year_end_date') }} then 'Retained Earnings'
            else 'Current Year Earnings'
        end as account_name,
        case
            when ledger.account_class in ('ASSET','EQUITY','LIABILITY') then ledger.account_code
            else null
        end as account_code,
        case
            when ledger.account_class in ('ASSET','EQUITY','LIABILITY') then ledger.account_id
            else null
        end as account_id,
        case
            when ledger.account_class in ('ASSET','EQUITY','LIABILITY') then ledger.account_type
            else null
        end as account_type,
        case
            when ledger.account_class in ('ASSET','EQUITY','LIABILITY') then ledger.account_class
            else 'EQUITY'
        end as account_class,
        ledger.source_relation, 
        sum(ledger.net_amount) as net_amount
    from calendar
    inner join ledger
        on calendar.date_month >= cast({{ dbt.date_trunc('month', 'ledger.journal_date') }} as date)
    cross join year_end
	where year_end.source_relation = ledger.source_relation
    {{ dbt_utils.group_by(7) }}

)

select *
from joined