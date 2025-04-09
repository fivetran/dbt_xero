{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

{%- set using_tracking_categories = (
    var('xero__using_invoice_line_item_tracking_category', True)
    and var('xero__using_tracking_categories', True)
) -%}

with staging as (

    select distinct
        invoice_id,
        line_item_id,
        source_relation
    from {{ ref('stg_xero__invoice_line_item_has_tracking_category') }}
    where option is not null
),

{% if using_tracking_categories %}
pivoted_tracking_categories as (

    select *
    from {{ ref('int_xero__invoice_line_item_pivoted_tracking_categories') }}

),
{% endif %}

line_items as (

    select *
    from {{ ref('stg_xero__invoice_line_item') }}

), invoices as (

    select *
    from {{ ref('stg_xero__invoice')  }}

), accounts as (

    select *
    from {{ ref('stg_xero__account') }}

), invoice_line_items_end as (

    select 
        line_items.invoice_id,
        line_items.line_item_id,
        line_items.source_relation

        {% if using_tracking_categories %}
        , {{ dbt_utils.star(
            from=ref('int_xero__invoice_line_item_pivoted_tracking_categories'),
            relation_alias='pivoted_tracking_categories',
            except=['invoice_id', 'line_item_id', 'source_relation']
        ) }}
        {% endif %}

    from line_items
    left join invoices
        on line_items.invoice_id = invoices.invoice_id
        and line_items.source_relation = invoices.source_relation
    left join accounts
        on line_items.account_code = accounts.account_code
        and line_items.source_relation = accounts.source_relation

    {% if using_tracking_categories %}
    inner join pivoted_tracking_categories
        on line_items.invoice_id = pivoted_tracking_categories.invoice_id
        and line_items.line_item_id = pivoted_tracking_categories.line_item_id
        and line_items.source_relation = pivoted_tracking_categories.source_relation
    {% endif %}
),

end_model as (

    select distinct
        invoice_id,
        line_item_id,
        source_relation
    from invoice_line_items_end
),

staging_not_in_end as (

    select * from staging
    except distinct
    select * from end_model
),

end_not_in_staging as (

    select * from end_model
    except distinct
    select * from staging
),

final as (

    select *, 'staging' as source
    from staging_not_in_end

    union all

    select *, 'end' as source
    from end_not_in_staging
)

select *
from final
