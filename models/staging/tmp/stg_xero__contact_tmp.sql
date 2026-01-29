{% if var('xero_sources') != [] %}

{{
    xero.xero_union_connections(
        connection_dictionary='xero_sources',
        single_source_name='xero',
        single_table_name='contact'
    )
}}

{% else %}

{{
    fivetran_utils.union_data(
        table_identifier='contact',
        database_variable='xero_database',
        schema_variable='xero_schema',
        default_database=target.database,
        default_schema='xero',
        default_variable='contact'
    )
}}

{% endif %}