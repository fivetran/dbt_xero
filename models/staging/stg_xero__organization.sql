
with base as (

    select * 
    from {{ ref('stg_xero__organization_tmp') }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_xero__organization_tmp')),
                staging_columns=get_organization_columns()
            )
        }}

        {{ xero.apply_source_relation() }}
    from base
),

final as (

    select
        source_relation,
        organisation_id,
        financial_year_end_month,
        financial_year_end_day
    from fields
)

select * from final
