with calendar as (

    select *
    from {{ ref('xero__calendar_spine') }}

), ledger as (

    select *
    from {{ ref('xero__general_ledger') }}

), joined as (

    select 
        {{ dbt_utils.surrogate_key(['calendar.date_month','ledger.account_id']) }} as profit_and_loss_id,
        calendar.date_month, 
        ledger.account_id,
        ledger.account_name,
        ledger.account_code,
        ledger.account_type, 
        ledger.account_class, 
        coalesce(sum(ledger.net_amount * -1),0) as net_amount
    from calendar
    left join ledger
        on calendar.date_month = cast({{ dbt_utils.date_trunc('month', 'ledger.journal_date') }} as date)
    where ledger.account_class in ('REVENUE','EXPENSE')
    {{ dbt_utils.group_by(7) }}

)

select *
from joined