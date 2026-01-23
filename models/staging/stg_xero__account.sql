
with base as (

    select * 
    from {{ ref('stg_xero__account_tmp') }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_xero__account_tmp')),
                staging_columns=get_account_columns()
            )
        }}

        {{ xero.apply_source_relation() }}
    from base
),

final as (

    select
        source_relation,
        account_id,
        name as account_name,
        code as account_code,
        type as account_type,
        class as account_class,
        _fivetran_synced
    from fields

)

select * from final
