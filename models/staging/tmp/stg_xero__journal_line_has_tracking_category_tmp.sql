{{ config(enabled=var('xero__using_journal_line_tracking_category', True)) }}

{% if var('xero_sources') != [] %}

{{
    xero.xero_union_connections(
        connection_dictionary='xero_sources',
        single_source_name='xero',
        single_table_name='journal_line_has_tracking_category'
    )
}}

{% else %}

{{
    fivetran_utils.union_data(
        table_identifier='journal_line_has_tracking_category',
        database_variable='xero_database',
        schema_variable='xero_schema',
        default_database=target.database,
        default_schema='xero',
        default_variable='journal_line_has_tracking_category'
    )
}}

{% endif %}