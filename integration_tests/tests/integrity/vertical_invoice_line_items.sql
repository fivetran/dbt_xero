{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with staging as (

    select distinct 
        line_item_id, 
        option
    from {{ ref('stg_xero__invoice_line_item_has_tracking_category') }}
    where option is not null
),

invoice_line_items as (

    select line_item_id, tracking_category_1 as option
    from {{ ref('xero__invoice_line_items') }}
    where tracking_category_1 is not null

    union distinct

    select line_item_id, tracking_category_2 as option
    from {{ ref('xero__invoice_line_items') }}
    where tracking_category_2 is not null
),


staging_not_invoice_line_items as (
    
    -- rows from staging not found in invoice line items
    select * from staging
    except distinct
    select * from invoice_line_items
),

invoice_line_items_not_staging as (

    -- rows from invoice line items not found in staging
    select * from invoice_line_items
    except distinct
    select * from staging
),

final as (

    select
        *,
        'from staging' as source
    from staging_not_invoice_line_items

    union all -- union since we only care if rows are produced

    select
        *,
        'from general ledger' as source
    from invoice_line_items_not_staging
)

select *
from final
