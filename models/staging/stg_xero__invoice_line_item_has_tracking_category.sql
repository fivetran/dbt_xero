{{ config(enabled=var('xero__using_invoice_line_item_tracking_category', True)) }}

with base as (

    select * 
    from {{ ref('stg_xero__invoice_line_item_has_tracking_category_tmp') }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_xero__invoice_line_item_has_tracking_category_tmp')),
                staging_columns=get_invoice_line_item_has_tracking_category_columns()
            )
        }}

        {{ fivetran_utils.add_dbt_source_relation() }}    
    from base
),

final as (
    
    select 
        invoice_id,
        line_item_id,
        tracking_category_id,
        option as tracking_option_name,
        _fivetran_synced

        {{ fivetran_utils.source_relation() }}
        
    from fields
)

select * 
from final
