{{ config(enabled=var('xero__using_credit_note', True)) }}

{% if var('xero_union_schemas', []) | length > 0 or var('xero_union_databases', []) | length > 0 %}

{{
    fivetran_utils.union_data(
        table_identifier='credit_note',
        database_variable='xero_database',
        schema_variable='xero_schema',
        default_database=target.database,
        default_schema='xero',
        default_variable='credit_note',
        union_schema_variable='xero_union_schemas',
        union_database_variable='xero_union_databases'
    )
}}

{% else %}

{{
    fivetran_utils.union_connections(
        connection_dictionary='xero_sources',
        single_source_name='xero',
        single_table_name='credit_note'
    )
}}

{% endif %}