with calendar as (

    select *
    from {{ ref('xero__calendar_spine') }}

), ledger as (

    select *
    from {{ ref('xero__general_ledger') }}

), organisation as (

    select *
    from {{ ref('stg_xero__organization') }}

), year_end as (

    select 
        case
            when cast(extract(year from current_date) || '-' || financial_year_end_month || '-' || financial_year_end_day as date) >= current_date
            then cast(extract(year from current_date) || '-' || financial_year_end_month || '-' || financial_year_end_day as date)
            else cast(extract(year from date_add(current_date, interval -1 year)) || '-' || financial_year_end_month || '-' || financial_year_end_day as date)
        end as current_year_end_date
    from organisation

), joined as (

    select
        calendar.date_month,
        case
            when ledger.account_class in ('ASSET','EQUITY','LIABILITY') then ledger.account_name
            when ledger.journal_date <= date_add(year_end.current_year_end_date, interval -1 year) then 'Retained Earnings'
            else 'Current Year Earnings'
        end as account_name,
        case
            when ledger.account_class in ('ASSET','EQUITY','LIABILITY') then ledger.account_code
            else null
        end as account_code,
        case
            when ledger.account_class in ('ASSET','EQUITY','LIABILITY') then ledger.account_class
            else 'EQUITY'
        end as account_class,
        sum(ledger.net_amount) as net_amount
    from calendar
    inner join ledger
        on calendar.date_month >= cast({{ dbt_utils.date_trunc('month', 'ledger.journal_date') }} as date)
    cross join year_end
    group by 1,2,3,4

)

select *
from joined