with ranked_tracking as (
    select
        line_item_id,
        source_relation,
        option,
        _fivetran_synced,
        tracking_category_id,
        row_number() over (
            partition by line_item_id, source_relation, option
            order by _fivetran_synced desc, tracking_category_id
        ) as dedup_rn -- deduplicate options
    from {{ var('invoice_line_item_has_tracking_category') }}
),

deduped_tracking as (
    select
        line_item_id,
        source_relation,
        option,
        _fivetran_synced,
        row_number() over (
            partition by line_item_id, source_relation
            order by _fivetran_synced desc, tracking_category_id
        ) as option_rank -- rank distinct options
    from ranked_tracking
    where dedup_rn = 1 -- distinct options only
),

pivoted_tracking as (
    select
        line_item_id,
        source_relation,
        max(case when option_rank = 1 then option end) as tracking_category_1,
        max(case when option_rank = 2 then option end) as tracking_category_2
    from deduped_tracking
    where option_rank <= 2
    group by line_item_id, source_relation
)

select *
from pivoted_tracking