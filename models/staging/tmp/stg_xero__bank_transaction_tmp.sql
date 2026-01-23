{{ config(enabled=var('xero__using_bank_transaction', True)) }}

{% if var('xero_sources') != [] %}

{{
    xero.xero_union_connections(
        connection_dictionary='xero_sources',
        single_source_name='xero',
        single_table_name='bank_transaction'
    )
}}

{% else %}

{{
    fivetran_utils.union_data(
        table_identifier='bank_transaction',
        database_variable='xero_database',
        schema_variable='xero_schema',
        default_database=target.database,
        default_schema='xero',
        default_variable='bank_transaction'
    )
}}

{% endif %}