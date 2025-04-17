{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with prod as (

    select 
        profit_and_loss_id,
        source_relation,
        net_amount
    from {{ target.schema }}_xero_prod.xero__profit_and_loss_report
),

dev as (

    select 
        profit_and_loss_id,
        source_relation,
        net_amount
    from {{ target.schema }}_xero_dev.xero__profit_and_loss_report
),

diffed as (
    select
        coalesce(prod.profit_and_loss_id, dev.profit_and_loss_id) as profit_and_loss_id,
        coalesce(prod.source_relation, dev.source_relation) as source_relation,
        prod.net_amount as prod_net_amount,
        dev.net_amount as dev_net_amount
    from prod
    full outer join dev
        on prod.profit_and_loss_id = dev.profit_and_loss_id 
        and prod.source_relation = dev.source_relation
),

final as (
    select *
    from diffed
    where abs(coalesce(prod_net_amount, 0) - coalesce(dev_net_amount, 0)) > 0.01
)

select *
from final