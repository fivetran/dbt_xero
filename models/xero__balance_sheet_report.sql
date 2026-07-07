with calendar as (

    select *
    from {{ ref('xero__calendar_spine') }}

), ledger as (

    select *
    from {{ ref('xero__general_ledger') }}

), organization as (

    select *
    from {{ ref('stg_xero__organization') }}

), calendar_organization as (

-- Derive the fiscal year from each report month (date_month) rather than from current_date,
-- so that each month's balance sheet is classified against its own fiscal year boundary.
    select
        calendar.date_month,
        organization.source_relation,
        organization.financial_year_end_month,
        organization.financial_year_end_day,
        cast(extract(year from calendar.date_month) as {{ dbt.type_string() }}) as date_month_year,
        cast(extract(year from {{ dbt.dateadd('year', 1, 'calendar.date_month') }}) as {{ dbt.type_string() }}) as date_month_next_year
    from calendar
    cross join organization

), year_end as (

-- Calculate the financial year-end date that applies to each report month (date_month):
-- For February, determine last day by subtracting 1 day from March 1, avoiding leap year logic.
-- Compare the year end date to the report month:
--   Use this year's date if it's on or after the report month.
--   Otherwise, use the next year's corresponding date.
    select
        date_month,
        source_relation,
        case when financial_year_end_month = 2 and financial_year_end_day = 29
            then
                case when cast({{ dbt.dateadd('day', -1, "cast(date_month_year || '-03-01' as date)") }} as date) >= date_month
                    then cast({{ dbt.dateadd('day', -1, "cast(date_month_year || '-03-01' as date)") }} as date)
                    else cast({{ dbt.dateadd('day', -1, "cast(date_month_next_year || '-03-01' as date)") }} as date)
                    end
            else
                case when cast(date_month_year || '-' || financial_year_end_month || '-' || financial_year_end_day as date) >= date_month
                    then cast(date_month_year || '-' || financial_year_end_month || '-' || financial_year_end_day as date)
                    else cast(date_month_next_year || '-' || financial_year_end_month || '-' || financial_year_end_day as date)
                    end
        end as current_year_end_date

    from calendar_organization

), joined as (

    select
        calendar.date_month,
        case
            when ledger.account_class in ('ASSET','EQUITY','LIABILITY') then ledger.account_name
            when cast(ledger.journal_date as date) <= {{ dbt.dateadd('year', -1, 'year_end.current_year_end_date') }} then 'Retained Earnings'
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
    inner join year_end
        on year_end.date_month = calendar.date_month
        and year_end.source_relation = ledger.source_relation
    {{ dbt_utils.group_by(7) }}

)

select *
from joined
