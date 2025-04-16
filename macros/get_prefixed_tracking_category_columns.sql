{% macro get_prefixed_tracking_category_columns(model_name, id_fields, alias='pivoted_tracking_categories') %}
    {{ return(adapter.dispatch('get_prefixed_tracking_category_columns', 'xero')(model_name, id_fields, alias)) }}
{% endmacro %}

{% macro default__get_prefixed_tracking_category_columns(model_name, id_fields, alias='pivoted_tracking_categories') %}
    {% set pivoted_columns = dbt_utils.get_filtered_columns_in_relation(
        from=ref(model_name),
        except=id_fields
    ) %}

    {% set prefixed_columns = [] %}
    {% for col in pivoted_columns %}
        {% do prefixed_columns.append(alias ~ '.' ~ col|lower) %}
    {% endfor %}

    {{ return(prefixed_columns) }}
{% endmacro %}
