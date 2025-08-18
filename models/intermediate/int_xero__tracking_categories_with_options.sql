{{ config(enabled=(var('xero__using_tracking_categories', True))) }}

with tracking_category as (

    select *
    from {{ ref('stg_xero__tracking_category') }}
    where lower(status) in ('active', 'archived')

), tracking_category_has_option as (

    select *
    from {{ ref('stg_xero__tracking_category_has_option') }}

), tracking_category_option as (

    select *
    from {{ ref('stg_xero__tracking_category_option') }}
    where lower(status) = 'active'
),

final as (

    select 
        tracking_category.tracking_category_id,
        tracking_category.tracking_category_name,
        tracking_category_option.tracking_option_id,
        tracking_category_option.tracking_option_name,
        tracking_category.source_relation
    from tracking_category
    left join tracking_category_has_option
        on tracking_category.tracking_category_id = tracking_category_has_option.tracking_category_id
        and tracking_category.source_relation = tracking_category_has_option.source_relation
    left join tracking_category_option
        on tracking_category_has_option.tracking_option_id = tracking_category_option.tracking_option_id
        and tracking_category_has_option.source_relation = tracking_category_option.source_relation
)

select *
from final