{{ config(enabled=(var('xero__using_invoice_line_item_tracking_category', True)
        and var('xero__using_tracking_category', True)
        and var('xero__using_tracking_category_option', True)
        and var('xero__using_tracking_category_has_option', True))) }}

with invoice_line_item_has_tracking as (

    select *
    from {{ var('invoice_line_item_has_tracking_category') }}

), tracking_category as (

    select *
    from {{ var('tracking_category') }}
    where lower(status) in ('active', 'archived')

), tracking_category_has_option as (

    select *
    from {{ var('tracking_category_has_option') }}

), tracking_category_option as (

    select *
    from {{ var('tracking_category_option') }}
    where lower(status) = 'active'

), invoice_tracking as (

    select
        invoice_line_item_has_tracking.invoice_id,
        invoice_line_item_has_tracking.line_item_id,
        invoice_line_item_has_tracking.source_relation,
        tracking_category.name as tracking_category_name,
        tracking_category_option.name as tracking_option_name
    from invoice_line_item_has_tracking

    left join tracking_category
        on invoice_line_item_has_tracking.tracking_category_id = tracking_category.tracking_category_id
        and invoice_line_item_has_tracking.source_relation = tracking_category.source_relation

    left join tracking_category_has_option
        on tracking_category.tracking_category_id = tracking_category_has_option.tracking_category_id
        and tracking_category.source_relation = tracking_category_has_option.source_relation

    left join tracking_category_option
        on tracking_category_has_option.tracking_option_id = tracking_category_option.tracking_option_id
        and tracking_category_has_option.source_relation = tracking_category_option.source_relation

), final as (

    select
        invoice_id,
        line_item_id,
        source_relation,
        {{ dbt_utils.pivot(
            column='tracking_category_name',
            values=dbt_utils.get_column_values(ref('stg_xero__tracking_category'), 'name'),
            agg='max',
            then_value='tracking_option_name',
            else_value='null',
            quote_identifiers=false
        ) }}
    from invoice_tracking
    {{ dbt_utils.group_by(3) }}
)

select *
from final