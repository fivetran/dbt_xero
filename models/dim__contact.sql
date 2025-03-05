with stg_contacts as (

    select 

     
       contact_id,
       contact_name

    


    from {{ ref('stg_xero__contact') }}

), final as (

    select
        {{ dbt_utils.generate_surrogate_key([' contact_id', ' contact_id']) }} AS ContactKey,
     contact_id,
     contact_name

     

    from stg_contacts

)

select * from final
