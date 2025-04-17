{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

{%- set using_tracking_categories = (
    var('xero__using_journal_line_tracking_category', True)
    and var('xero__using_tracking_categories', True)
) -%}

with staging as (

    select distinct 
        journal_id,
        journal_line_id,
        source_relation
    from {{ ref('stg_xero__journal_line_has_tracking_category') }}
    where option is not null
)

{% if using_tracking_categories %}
, pivoted_tracking_categories as (

    select *
    from {{ ref('int_xero__journal_line_pivoted_tracking_categories') }}

){% endif %}

, journals as (

    select *
    from {{ ref('stg_xero__journal') }}

), journal_lines as (

    select *
    from {{ ref('stg_xero__journal_line') }}
),

accounts as (

    select *
    from {{ ref('stg_xero__account') }}
),

general_ledger as (

    select 
        journals.journal_id, 
        journal_lines.journal_line_id,
        journals.source_relation,
        {% if using_tracking_categories %}
        -- Pivoted tracking categories, excluding duplicate columns
        {{ dbt_utils.star(
            from=ref('int_xero__journal_line_pivoted_tracking_categories'),
            relation_alias='pivoted_tracking_categories',
            except=['journal_id', 'journal_line_id', 'source_relation']
        ) }}
        {% endif %}

    from journals
    left join journal_lines
        on (journals.journal_id = journal_lines.journal_id
        and journals.source_relation = journal_lines.source_relation)
    left join accounts
        on (accounts.account_id = journal_lines.account_id
        and accounts.source_relation = journal_lines.source_relation)

    {% if using_tracking_categories %}
    inner join pivoted_tracking_categories
        on (journal_lines.journal_line_id = pivoted_tracking_categories.journal_line_id
        and journals.journal_id = pivoted_tracking_categories.journal_id
        and journals.source_relation = pivoted_tracking_categories.source_relation)
    {% endif %}
),

end_model as (

    select distinct 
        journal_id,
        journal_line_id,
        source_relation
    from general_ledger
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
    select *, 'from staging' as source
    from staging_not_in_end

    union all

    select *, 'from end model' as source
    from end_not_in_staging
)

select *
from final