{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with prod as (
    select *
    from {{ target.schema }}_xero_prod.xero__balance_sheet_report
),

dev as (
    select *
    from {{ target.schema }}_xero_dev.xero__balance_sheet_report
),

diffed as (
    select
        coalesce(prod.date_month, dev.date_month) as date_month,
        coalesce(prod.account_id, dev.account_id) as account_id,
        coalesce(prod.source_relation, dev.source_relation) as source_relation,
        prod.net_amount as prod_net_amount,
        dev.net_amount as dev_net_amount
    from prod
    inner join dev
        on prod.date_month = dev.date_month
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