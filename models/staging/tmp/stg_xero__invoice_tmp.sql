{{ config(enabled=var('xero__using_invoice', True)) }}

{% if var('union_schemas', []) | length > 0 or var('union_databases', []) | length > 0 %}

{{
    fivetran_utils.union_data(
        table_identifier='invoice',
        database_variable='xero_database',
        schema_variable='xero_schema',
        default_database=target.database,
        default_schema='xero',
        default_variable='invoice'
    )
}}

{% else %}

{{
    fivetran_utils.union_connections(
        connection_dictionary='xero_sources',
        single_source_name='xero',
        single_table_name='invoice'
    )
}}

{% endif %}