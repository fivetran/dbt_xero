{% macro get_journal_line_has_tracking_category_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "journal_id", "datatype": dbt.type_string()},
    {"name": "journal_line_id", "datatype": dbt.type_string()},
    {"name": "option", "datatype": dbt.type_string()},
    {"name": "tracking_category_id", "datatype": dbt.type_string()},
    {"name": "tracking_category_option_id", "datatype": dbt.type_string()}
] %}

{{ return(columns) }}

{% endmacro %}