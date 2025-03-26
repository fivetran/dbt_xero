-- Test to analyze trends in employee remuneration report
-- This test checks for month-to-month consistency and identifies outliers

with monthly_totals as (
    select
        date_month,
        sum(amount) as total_amount
    from {{ ref('xero__employee_remuneration_report') }}
    group by 1
    order by 1
),

month_over_month_change as (
    select
        current_month.date_month,
        current_month.total_amount,
        prev_month.total_amount as prev_month_amount,
        (current_month.total_amount - prev_month.total_amount) as absolute_change,
        case 
            when prev_month.total_amount = 0 then null
            else (current_month.total_amount - prev_month.total_amount) / prev_month.total_amount 
        end as percent_change
    from monthly_totals as current_month
    left join monthly_totals as prev_month
        on current_month.date_month = date_add(prev_month.date_month, interval 1 month)
),

-- Identify months with more than 30% change in payroll expenses
outlier_months as (
    select
        date_month,
        total_amount,
        prev_month_amount,
        percent_change
    from month_over_month_change
    where abs(percent_change) > 0.3  -- 30% change threshold
)

-- This test will fail if we find outlier months
-- It's not necessarily an error, but highlights months for review
select
    date_month,
    'Large month-over-month change in payroll expenses' as failure_reason,
    concat(
        'Change of ', 
        round(percent_change * 100, 1),
        '% from previous month (', 
        prev_month_amount,
        ' to ',
        total_amount,
        ')'
    ) as details
from outlier_months