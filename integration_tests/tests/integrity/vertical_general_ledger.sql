{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

{%- set using_tracking_categories = (
    var('xero__using_journal_line_has_tracking_category', True)
    and var('xero__using_tracking_category', True)
    and var('xero__using_tracking_category_option', True)
    and var('xero__using_tracking_category_has_option', True)
) -%}

with staging as (

    select distinct 
        journal_id,
        journal_line_id,
        source_relation
    from {{ ref('stg_xero__journal_line_has_tracking_category') }}
    where option is not null
),

{% if using_tracking_categories %}
, pivoted_tracking_categories as (

    select *
    from {{ ref('int_xero__journal_line_pivoted_tracking_categories') }}

){% endif %}


journals as (

    select *
    from {{ var('journal') }}

), journal_lines as (

    select *
    from {{ var('journal_line') }}
),

general_ledger_base as (

    select 
        journals.journal_id, 
        journal_lines.journal_line_id,
        journals.source_relation
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

general_ledger as (

    select distinct 
        journal_id,
        journal_line_id,
        source_relation
    from general_ledger_base
),

staging_not_general_ledger as (
    
    -- rows from staging not found in gl
    select * from staging
    except distinct
    select * from general_ledger
),

general_ledger_not_staging as (

    -- rows from dev not found in prod
    select * from general_ledger
    except distinct
    select * from staging
),

final as (
    select
        *,
        'from staging' as source
    from staging_not_general_ledger

    union all -- union since we only care if rows are produced

    select
        *,
        'from general ledger' as source
    from general_ledger_not_staging
)

select *
from final
