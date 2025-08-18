{% macro get_tracking_category_has_option_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "tracking_category_id", "datatype": dbt.type_string()},
    {"name": "tracking_option_id", "datatype": dbt.type_string()}
] %}

{{ return(columns) }}

{% endmacro %}