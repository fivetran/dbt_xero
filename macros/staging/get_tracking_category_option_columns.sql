{% macro get_tracking_category_option_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "has_validation_errors", "datatype": dbt.type_boolean()},
    {"name": "is_active", "datatype": dbt.type_boolean()},
    {"name": "is_archived", "datatype": dbt.type_boolean()},
    {"name": "is_deleted", "datatype": dbt.type_boolean()},
    {"name": "name", "datatype": dbt.type_string()},
    {"name": "status", "datatype": dbt.type_string()},
    {"name": "tracking_option_id", "datatype": dbt.type_string()}
] %}

{{ return(columns) }}

{% endmacro %}