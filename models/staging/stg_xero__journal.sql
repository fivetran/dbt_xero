
with base as (

    select * 
    from {{ ref('stg_xero__journal_tmp') }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_xero__journal_tmp')),
                staging_columns=get_journal_columns()
            )
        }}

        {{ xero.apply_source_relation() }}
    from base
),

final as (

    select
        source_relation,
        journal_id,
        created_date_utc,
        journal_date,
        journal_number,
        reference,
        source_id,
        source_type
    from fields
)

select * from final
