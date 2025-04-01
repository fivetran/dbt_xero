{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with staging_journals as (

    select *
    from {{ ref('stg_xero__journal') }}
), 

staging_journal_lines as (

    select *
    from {{ ref('stg_xero__journal_line') }}
), 

staging_accounts as (

    select *
    from {{ ref('stg_xero__account') }}
),

staging_tracking_categories_raw as (

    select
        journal_line_id,
        option,
        tracking_category_id,
        _fivetran_synced
    from {{ ref('stg_xero__journal_line_has_tracking_category') }}
    where option is not null
), 

profit_and_loss as ( 

    select *
    from {{ ref('xero__profit_and_loss_report') }}
),

calendar as ( 

    select *
    from {{ ref('xero__calendar_spine') }}
),

ranked_tracking_categories as (

    select *,
        row_number() over (
            partition by journal_line_id, option
            order by _fivetran_synced desc, tracking_category_id
        ) as deduplication_rank
    from staging_tracking_categories_raw
),

deduplicated_tracking_categories as (

    select *
    from ranked_tracking_categories
    where deduplication_rank = 1
),

ranked_tracking_options_per_line as (

    select *,
        row_number() over (
            partition by journal_line_id
            order by _fivetran_synced desc, tracking_category_id
        ) as option_rank
    from deduplicated_tracking_categories
),

pivoted_tracking_categories as (

    select
        journal_line_id,
        max(case when option_rank = 1 then option end) as tracking_category_1,
        max(case when option_rank = 2 then option end) as tracking_category_2
    from ranked_tracking_options_per_line
    where option_rank <= 2
    group by journal_line_id
),

reconstructed_general_ledger_from_staging as (

    select
        cast({{ dbt.date_trunc('month', 'staging_journals.journal_date') }} as date) as date_month,
        staging_journal_lines.account_id,  
        staging_accounts.account_class, 
        staging_accounts.account_name,
        staging_accounts.account_code,
        staging_accounts.account_type,
        coalesce(pivoted_tracking_categories.tracking_category_1, '') as tracking_category_1,
        coalesce(pivoted_tracking_categories.tracking_category_2, '') as tracking_category_2,
        staging_journal_lines.net_amount as adjusted_net_amount
    from staging_journals 
    left join staging_journal_lines
        on staging_journals.journal_id = staging_journal_lines.journal_id
    left join staging_accounts
        on staging_journal_lines.account_id = staging_accounts.account_id
    left join pivoted_tracking_categories
        on staging_journal_lines.journal_line_id = pivoted_tracking_categories.journal_line_id
),

aggregated_staging_profit_and_loss as (

    select
        calendar.date_month,
        account_id, 
        account_class,
        account_name, 
        account_code,
        account_type,
        tracking_category_1,
        tracking_category_2,
        coalesce(sum(adjusted_net_amount * -1),0) as net_amount
    from calendar
    left join reconstructed_general_ledger_from_staging
        on calendar.date_month = cast({{ dbt.date_trunc('month', 'reconstructed_general_ledger_from_staging.date_month') }} as date)
    where account_class in ('REVENUE','EXPENSE')
    group by 1, 2, 3, 4, 5, 6, 7, 8
),

profit_and_loss_model as (

    select 
        cast({{ dbt.date_trunc('month', 'date_month') }} as date) as date_month,
        account_id,
        account_class,
        account_name, 
        account_code,
        account_type,
        coalesce(tracking_category_1, '') as tracking_category_1,
        coalesce(tracking_category_2, '') as tracking_category_2,
        net_amount as profit_and_loss_net_amount
    from profit_and_loss
),

comparison_between_models as (

    select
        coalesce(profit_and_loss_model.date_month, aggregated_staging_profit_and_loss.date_month) as date_month,
        coalesce(profit_and_loss_model.account_id, aggregated_staging_profit_and_loss.account_id) as account_id, 
        coalesce(profit_and_loss_model.tracking_category_1, aggregated_staging_profit_and_loss.tracking_category_1) as tracking_category_1,
        coalesce(profit_and_loss_model.tracking_category_2, aggregated_staging_profit_and_loss.tracking_category_2) as tracking_category_2,
        coalesce(profit_and_loss_model.profit_and_loss_net_amount, 0) as profit_and_loss_net_amount,
        coalesce(aggregated_staging_profit_and_loss.net_amount, 0) as staging_net_amount,
        round(coalesce(profit_and_loss_model.profit_and_loss_net_amount, 0) - coalesce(aggregated_staging_profit_and_loss.net_amount, 0), 2) as net_amount_difference
    from profit_and_loss_model
    full outer join aggregated_staging_profit_and_loss
        on profit_and_loss_model.date_month = aggregated_staging_profit_and_loss.date_month
        and profit_and_loss_model.account_id = aggregated_staging_profit_and_loss.account_id
        and profit_and_loss_model.tracking_category_1 = aggregated_staging_profit_and_loss.tracking_category_1
        and profit_and_loss_model.tracking_category_2 = aggregated_staging_profit_and_loss.tracking_category_2
)

select *
from comparison_between_models
where abs(net_amount_difference) > 0.01