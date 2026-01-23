{% macro apply_source_relation() -%}

{{ adapter.dispatch('apply_source_relation', 'xero') () }}

{%- endmacro %}

{% macro default__apply_source_relation() -%}

{% if var('xero_sources', []) != [] %}
, _dbt_source_relation as source_relation
{% elif var('union_schemas', []) != []  or var('union_databases', []) != [] %}
{{ fivetran_utils.source_relation() }}
{% else %}
, '{{ var("xero_database", target.database) }}' || '.'|| '{{ var("xero_schema", "xero") }}' as source_relation
{% endif %}

{%- endmacro %}