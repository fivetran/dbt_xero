with calendar as (

    select *
    from {{ ref('xero__calendar_spine') }}

), ledger as (
    select *
    from {{ ref('xero__general_ledger') }}

), payroll_account_references as (
    
    {% if false %}
    -- For testing, we use our seed data with explicit payroll accounts
    -- Disabling this section temporarily due to seed issues
    select
        account_id
    from {{ source('integration_tests', 'xero_payroll_account_data') }}
    where class = 'EXPENSE'
    
    {% else %}
    -- For production, we identify payroll accounts by name patterns
    select distinct
        account_id
    from {{ ref('xero__general_ledger') }}
    where account_class = 'EXPENSE'
    and (
        -- Common payroll expense account types
        lower(account_name) like '%salary%'
        or lower(account_name) like '%wage%'
        or lower(account_name) like '%payroll%'
        or lower(account_name) like '%bonus%'
        or lower(account_name) like '%commission%'
        or lower(account_name) like '%superannuation%'
        or lower(account_name) like '%pension%'
        or lower(account_name) like '%benefit%'
        or lower(account_name) like '%training%'
        -- Add more account filters as needed
    )
    {% endif %}

), payroll_accounts as (
    select *
    from ledger
    where account_class = 'EXPENSE'
    and account_id in (select account_id from payroll_account_references)

), joined as (

    select 
        {{ dbt_utils.generate_surrogate_key(['calendar.date_month','payroll_accounts.account_id','payroll_accounts.source_relation']) }} as employee_remuneration_id,
        calendar.date_month, 
        payroll_accounts.account_id,
        payroll_accounts.account_name,
        payroll_accounts.account_code,
        payroll_accounts.account_type, 
        coalesce(sum(payroll_accounts.net_amount * -1), 0) as amount,
        payroll_accounts.source_relation
    from calendar
    left join payroll_accounts
        on calendar.date_month = cast({{ dbt.date_trunc('month', 'payroll_accounts.journal_date') }} as date)
    group by 
        calendar.date_month,
        payroll_accounts.account_id,
        payroll_accounts.account_name,
        payroll_accounts.account_code,
        payroll_accounts.account_type,
        payroll_accounts.source_relation

), totals as (

    select
        date_month,
        source_relation,
        sum(amount) as total_payroll_amount
    from joined
    group by 1, 2

), final as (

    select
        joined.*,
        totals.total_payroll_amount,
        case 
            when totals.total_payroll_amount = 0 then 0
            else joined.amount / totals.total_payroll_amount 
        end as percent_of_total
    from joined
    left join totals
        on joined.date_month = totals.date_month
        and joined.source_relation = totals.source_relation

)

select *
from final