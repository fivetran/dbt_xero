{{ config(enabled=var('xero__using_tracking_categories', True)) }}

{% if var('xero_sources') != [] %}

{{
    xero.xero_union_connections(
        connection_dictionary='xero_sources',
        single_source_name='xero',
        single_table_name='tracking_category_option'
    )
}}

{% else %}

{{
    fivetran_utils.union_data(
        table_identifier='tracking_category_option',
        database_variable='xero_database',
        schema_variable='xero_schema',
        default_database=target.database,
        default_schema='xero',
        default_variable='tracking_category_option'
    )
}}

{% endif %}