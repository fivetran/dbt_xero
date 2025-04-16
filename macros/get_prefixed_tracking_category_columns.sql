{% macro get_prefixed_tracking_category_columns(model_name, id_fields, alias='pivoted_tracking_categories') %}
    {{ return(adapter.dispatch('get_prefixed_tracking_category_columns', 'xero')(model_name, id_fields, alias)) }}
{% endmacro %}

{% macro default__get_prefixed_tracking_category_columns(model_name, id_fields, alias='pivoted_tracking_categories') %}
    {% set pivoted_columns = dbt_utils.get_filtered_columns_in_relation(
        from=ref('int_xero__' ~ model_name),
        except=id_fields
    ) %}

    {% if raw_columns is not iterable or raw_columns | length == 0 %}
        {% set prefixed_columns = [] %}
    {% else %}
        {% if lowercase %}
            {% set raw_columns = raw_columns | map('lower') | list %}
        {% endif %}

        {% set prefixed_columns = [] %}
        {% for col in raw_columns %}
            {% do prefixed_columns.append(alias ~ '.' ~ col) %}
        {% endfor %}
    {% endif %}

    {{ return(prefixed_columns) }}
{% endmacro %}
