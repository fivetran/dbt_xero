{% macro get_pivoted_tracking_category_columns(model_name, id_fields) %}
    {{ return(adapter.dispatch('get_pivoted_tracking_category_columns', 'xero')(model_name, id_fields)) }}
{% endmacro %}

{% macro default__get_pivoted_tracking_category_columns(model_name, id_fields) %}

    {%- set tracking_category_columns = dbt_utils.get_filtered_columns_in_relation(
        from=ref(model_name),
        except=id_fields
    ) %}

    {{ return(tracking_category_columns | map('lower') | list) }}
{% endmacro %}