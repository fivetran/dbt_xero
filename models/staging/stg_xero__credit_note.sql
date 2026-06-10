{{ config(enabled=var('xero__using_credit_note', True)) }}

with base as (

    select * 
    from {{ ref('stg_xero__credit_note_tmp') }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_xero__credit_note_tmp')),
                staging_columns=get_credit_note_columns()
            )
        }}

        {{ fivetran_utils.apply_source_relation(package_name='xero') }}
    from base
),

final as (

    select
        source_relation,
        credit_note_id,
        contact_id
    from fields
)

select * from final