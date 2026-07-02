{{ config(enabled=var('xero__using_journal_cash_line_tracking_category', true)) }}

{% if var('union_schemas', []) | length > 0 or var('union_databases', []) | length > 0 %}

{{
    fivetran_utils.union_data(
        table_identifier='journal_cash_line_has_tracking_category',
        database_variable='xero_database',
        schema_variable='xero_schema',
        default_database=target.database,
        default_schema='xero',
        default_variable='journal_cash_line_has_tracking_category'
    )
}}

{% else %}

{{
    fivetran_utils.union_connections(
        connection_dictionary='xero_sources',
        single_source_name='xero',
        single_table_name='journal_cash_line_has_tracking_category'
    )
}}

{% endif %}