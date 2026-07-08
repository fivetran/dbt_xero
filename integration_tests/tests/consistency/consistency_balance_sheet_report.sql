{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

-- account_name is included in the grain because the `Retained Earnings` and `Current Year Earnings`
-- roll-up rows both have a null account_id; keying on account_id alone collapses them into one key
-- and produces a many-to-many diff.

with prod as (

    select
        date_month,
        account_name,
        case when account_id is null then '' else account_id end as account_id,
        source_relation,
        net_amount
    from {{ target.schema }}_xero_prod.xero__balance_sheet_report
),

dev as (

    select
        date_month,
        account_name,
        case when account_id is null then '' else account_id end as account_id,
        source_relation,
        net_amount
    from {{ target.schema }}_xero_dev.xero__balance_sheet_report
),

diffed as (
    select
        coalesce(prod.date_month, dev.date_month) as date_month,
        coalesce(prod.account_name, dev.account_name) as account_name,
        coalesce(prod.account_id, dev.account_id) as account_id,
        coalesce(prod.source_relation, dev.source_relation) as source_relation,
        prod.net_amount as prod_net_amount,
        dev.net_amount as dev_net_amount
    from prod
    full outer join dev
        on prod.date_month = dev.date_month
        and prod.account_name = dev.account_name
        and prod.account_id = dev.account_id
        and prod.source_relation = dev.source_relation
),

final as (
    select *
    from diffed
    where abs(coalesce(prod_net_amount, 0) - coalesce(dev_net_amount, 0)) > 0.01
)

select *
from final
