with calendar as (

    select *
    from {{ ref('xero__calendar_spine') }}

), ledger as (

    select *
    from {{ ref('xero__general_ledger') }}

), organization as (

    select *
    from {{ var('organization') }}

), year_end as (

    select 
        case
            when cast(extract(year from current_date) || '-' || financial_year_end_month || '-' || financial_year_end_day as date) >= current_date
            then cast(extract(year from current_date) || '-' || financial_year_end_month || '-' || financial_year_end_day as date)
            else case when financial_year_end_month = 2 and financial_year_end_day = 29 
                then cast(extract(year from {{ dbt.dateadd('year', -1, 'current_date') }}) || '-' || financial_year_end_month || '-28' as date) -- Necessary for organizations with a reported fiscal year end of 02-29 as the previous year will not be a leap year and must be the 28th. 
                else cast(extract(year from {{ dbt.dateadd('year', -1, 'current_date') }}) || '-' || financial_year_end_month || '-' || financial_year_end_day as date)
            end
        end as current_year_end_date,
		source_relation
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