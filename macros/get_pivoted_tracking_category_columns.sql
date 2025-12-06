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

{% macro prefix_tracking_category_columns(columns, alias) %}
    {{ return(adapter.dispatch('prefix_tracking_category_columns', 'xero')(columns, alias)) }}
{% endmacro %}

{% macro default__prefix_tracking_category_columns(columns, alias) %}
    {% if alias and columns|length > 0 %}
        {% set prefixed_columns = [] %}
        {% for col in columns %}
            {% do prefixed_columns.append(alias ~ '.' ~ col) %}
        {% endfor %}
        {{ return(prefixed_columns) }}
    {% else %}
        {{ return(columns) }}
    {% endif %}
{% endmacro %}