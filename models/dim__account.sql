with stg_accounts as (

    select * 
    from {{ ref('stg_xero__account_tmp') }}

), final as (

    select

        {{ dbt_utils.generate_surrogate_key([' account_id',' account_id']) }} as account_key,
        account_id,
        name as account_name,
        code as account_code,
        type as account_type,
        class as account_class,
        _fivetran_synced
    from stg_accounts

)

select * from final