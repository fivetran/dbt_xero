{{ config(enabled=(var('xero__using_invoice_line_item_tracking_category', True)
        and var('xero__using_tracking_categories', True))) }}

{% set pivot_values = dbt_utils.get_column_values(
    ref('int_xero__tracking_categories_with_options'),
    'tracking_category_name'
) %}

with invoice_line_item_has_tracking as (

    select *
    from {{ var('invoice_line_item_has_tracking_category') }}

), tracking_categories_with_options as (

    select *
    from {{ ref('int_xero__tracking_categories_with_options') }}

), invoice_tracking as (

    select
        invoice_line_item_has_tracking.invoice_id,
        invoice_line_item_has_tracking.line_item_id,
        invoice_line_item_has_tracking.source_relation,
        tracking_categories_with_options.tracking_category_name,
        tracking_categories_with_options.tracking_option_name
    from invoice_line_item_has_tracking

    left join tracking_categories_with_options
        on invoice_line_item_has_tracking.tracking_category_id = tracking_categories_with_options.tracking_category_id
        and invoice_line_item_has_tracking.tracking_option_name = tracking_categories_with_options.tracking_option_name
        and invoice_line_item_has_tracking.source_relation = tracking_categories_with_options.source_relation

), final as (

    select
        invoice_id,
        line_item_id,
        source_relation
        {% if pivot_values is not none and pivot_values | length > 0 %}
        ,   {{ dbt_utils.pivot(
                column='tracking_category_name',
                values=dbt_utils.get_column_values(ref('int_xero__tracking_categories_with_options'), 'tracking_category_name'),
                agg='max',
                then_value='tracking_option_name',
                else_value='null',
                quote_identifiers=false
            ) }}
        {% endif %}
    from invoice_tracking
    {{ dbt_utils.group_by(3) }}
)

select *
from final