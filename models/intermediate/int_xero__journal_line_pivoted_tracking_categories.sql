{{ config(enabled=(var('xero__using_journal_line_tracking_category', True)
        and var('xero__using_tracking_categories', True))) }}

{% set pivot_values = dbt_utils.get_column_values(
    ref('int_xero__tracking_categories_with_options'),
    'tracking_category_name'
) %}

with journal_line_has_tracking as (

    select *
    from {{ var('journal_line_has_tracking_category') }}

), tracking_categories_with_options as (

    select *
    from {{ ref('int_xero__tracking_categories_with_options') }}

), journal_tracking as (

    select
        journal_line_has_tracking.journal_id,
        journal_line_has_tracking.journal_line_id,
        journal_line_has_tracking.source_relation,
        tracking_categories_with_options.tracking_category_name,
        tracking_categories_with_options.tracking_option_name
    from journal_line_has_tracking

    left join tracking_categories_with_options
        on journal_line_has_tracking.tracking_category_id = tracking_categories_with_options.tracking_category_id
        and journal_line_has_tracking.tracking_category_option_id = tracking_categories_with_options.tracking_option_id
        and journal_line_has_tracking.source_relation = tracking_categories_with_options.source_relation
),

final as (

    select
        journal_id,
        journal_line_id,
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
    from journal_tracking
    {{ dbt_utils.group_by(3) }}
)

select *
from final