{{ config(enabled=var('xero__using_tracking_categories', True)) }}

with base as (

    select * 
    from {{ ref('stg_xero__tracking_category_option_tmp') }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_xero__tracking_category_option_tmp')),
                staging_columns=get_tracking_category_option_columns()
            )
        }}

        {{ xero.apply_source_relation() }}
    from base
),

final as (

    select
        source_relation,
        tracking_option_id,
        name as tracking_option_name,
        status,
        has_validation_errors,
        is_active,
        is_archived,
        is_deleted,
        _fivetran_synced
    from fields
)

select * 
from final
