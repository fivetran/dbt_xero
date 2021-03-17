with calendar as (

    select *
    from {{ ref('xero__calendar_spine') }}

), ledger as (

    select *
    from {{ ref('xero__general_ledger') }}

), joined as (

    select
        calendar.date_month,
        case
            when ledger.account_class in ('ASSET','EQUITY','LIABILITY') then ledger.account_name
            else 'Net Income / Retained Earnings Adjustment'
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
    group by 1,2,3,4

)

select *
from joined