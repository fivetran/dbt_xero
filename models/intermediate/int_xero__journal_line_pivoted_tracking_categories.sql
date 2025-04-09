{{ config(enabled=(var('xero__using_journal_line_has_tracking_category', True)
        and var('xero__using_tracking_categories', True))) }}

with journal_line_has_tracking as (

    select *
    from {{ var('journal_line_has_tracking_category') }}
),

tracking_category as (

    select *
    from {{ var('tracking_category') }}
    where lower(status) in ('active', 'archived')
),

tracking_category_option as (

    select *
    from {{ var('tracking_category_option') }}
    where lower(status) = 'active'
),

journal_tracking as (

    select
        journal_line_has_tracking.journal_id,
        journal_line_has_tracking.journal_line_id,
        journal_line_has_tracking.source_relation,
        tracking_category.name as tracking_category_name,
        tracking_category_option.name as tracking_option_name
    from journal_line_has_tracking

    left join tracking_category
        on journal_line_has_tracking.tracking_category_id = tracking_category.tracking_category_id
        and journal_line_has_tracking.source_relation = tracking_category.source_relation

    left join tracking_category_option
        on journal_line_has_tracking.tracking_category_option_id = tracking_category_option.tracking_option_id
        and journal_line_has_tracking.source_relation = tracking_category_option.source_relation
),

final as (

    select
        journal_id,
        journal_line_id,
        source_relation,
        {{ dbt_utils.pivot(
            column='tracking_category_name',
            values=dbt_utils.get_column_values(ref('stg_xero__tracking_category'), 'name'),
            agg='max',
            then_value='tracking_option_name',
            else_value='null',
            quote_identifiers=false
        ) }} 
    from journal_tracking
    {{ dbt_utils.group_by(3) }}
)
select *
from final
