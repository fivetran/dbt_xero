{{ config(enabled=var('xero__using_invoice_line_item_tracking_category', True)) }}

{% if var('xero_sources', []) != [] %}

{{
    xero.xero_union_connections(
        connection_dictionary='xero_sources',
        single_source_name='xero',
        single_table_name='invoice_line_item_has_tracking_category'
    )
}}

{% else %}

{{
    fivetran_utils.union_data(
        table_identifier='invoice_line_item_has_tracking_category',
        database_variable='xero_database',
        schema_variable='xero_schema',
        default_database=target.database,
        default_schema='xero',
        default_variable='invoice_line_item_has_tracking_category'
    )
}}

{% endif %}