-- Test ensures that the total in the employee remuneration report
-- matches the sum of relevant payroll-related expenses in the general ledger

with remuneration_report as (
    select 
        date_month,
        source_relation,
        sum(amount) as total_from_report
    from {{ ref('xero__employee_remuneration_report') }}
    group by 1, 2
),

-- Use our payroll account data to filter the general ledger
payroll_accounts as (
    select
        account_id
    from {{ ref('xero_payroll_account_data') }} 
    where class = 'EXPENSE'
),

general_ledger as (
    select 
        cast({{ dbt.date_trunc('month', 'journal_date') }} as date) as date_month,
        source_relation,
        sum(net_amount * -1) as total_from_ledger
    from {{ ref('xero__general_ledger') }}
    where account_class = 'EXPENSE'
    and account_id in (select account_id from payroll_accounts)
    group by 1, 2
)

select
    remuneration_report.date_month,
    remuneration_report.source_relation,
    remuneration_report.total_from_report,
    general_ledger.total_from_ledger,
    abs(remuneration_report.total_from_report - general_ledger.total_from_ledger) as difference
from remuneration_report
join general_ledger
    on remuneration_report.date_month = general_ledger.date_month
    and remuneration_report.source_relation = general_ledger.source_relation
where abs(remuneration_report.total_from_report - general_ledger.total_from_ledger) > 0.01 -- Allow for small rounding differences