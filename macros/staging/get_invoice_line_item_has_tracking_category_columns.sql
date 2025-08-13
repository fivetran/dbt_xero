{% macro get_invoice_line_item_has_tracking_category_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "invoice_id", "datatype": dbt.type_string()},
    {"name": "line_item_id", "datatype": dbt.type_string()},
    {"name": "option", "datatype": dbt.type_string()},
    {"name": "tracking_category_id", "datatype": dbt.type_string()}
] %}

{{ return(columns) }}

{% endmacro %}