{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with staging as (

    select distinct 
        journal_line_id, 
        option
    from {{ ref('stg_xero__journal_line_has_tracking_category') }}
    where option is not null
),

general_ledger as (

    select journal_line_id, tracking_category_1 as option
    from {{ ref('xero__general_ledger') }}
    where tracking_category_1 is not null

    union distinct

    select journal_line_id, tracking_category_2 as option
    from {{ ref('xero__general_ledger') }}
    where tracking_category_2 is not null
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
