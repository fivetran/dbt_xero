{{ config(enabled=var('xero__using_journal_cash', true)) }}

{%- set using_tracking_categories = (
    var('xero__using_journal_cash_line_tracking_category', True)
    and var('xero__using_tracking_categories', True)
) -%}

{% set pivoted_columns = xero.get_pivoted_tracking_category_columns(
    model_name='int_xero__journal_cash_line_pivoted_tracking_categories',
    id_fields=['journal_id', 'journal_line_id', 'source_relation']
) if using_tracking_categories else [] %}

with journals as (

    select *
    from {{ ref('stg_xero__journal_cash') }}

), journal_lines as (

    select *
    from {{ ref('stg_xero__journal_cash_line') }}

), accounts as (

    select *
    from {{ ref('stg_xero__account') }}

{% if using_tracking_categories %}
), pivoted_tracking_categories as (

    select *
    from {{ ref('int_xero__journal_cash_line_pivoted_tracking_categories') }}
{% endif %}

), joined as (

    select
        journals.journal_id,
        journals.created_date_utc,
        journals.journal_date,
        journals.journal_number,
        journals.reference,
        journals.source_id,
        journals.source_type,
        journals.source_relation,
        journal_lines.journal_line_id,
        accounts.account_code,
        accounts.account_id,
        accounts.account_name,
        accounts.account_type,
        journal_lines.description,
        journal_lines.gross_amount,
        journal_lines.net_amount,
        journal_lines.tax_amount,
        journal_lines.tax_name,
        journal_lines.tax_type,
        accounts.account_class,
        'cash' as accounting_basis

        {% if using_tracking_categories and pivoted_columns|length > 0 %}
            {%- set accounts_columns = ['account_class', 'account_code', 'account_id', 'account_name', 'account_type'] %}
            {%- set journals_columns = ['accounting_basis', 'created_date_utc', 'journal_date', 'journal_id', 'journal_number', 'reference', 'source_id', 'source_relation', 'source_type'] %}
            {%- set journal_lines_columns = ['description', 'gross_amount', 'journal_line_id', 'net_amount', 'tax_amount', 'tax_name', 'tax_type'] %}
            {%- set joined_columns = accounts_columns + journals_columns + journal_lines_columns %}

            {% for col in pivoted_columns %}
                , pivoted_tracking_categories.{{ col }} {{ 'as pivoted_' ~ col if col in joined_columns }}
            {% endfor %}
        {% endif %}

    from journals
    left join journal_lines
        on journals.journal_id = journal_lines.journal_id
        and journals.source_relation = journal_lines.source_relation
    left join accounts
        on accounts.account_id = journal_lines.account_id
        and accounts.source_relation = journal_lines.source_relation

    {% if using_tracking_categories %}
    left join pivoted_tracking_categories
        on journal_lines.journal_line_id = pivoted_tracking_categories.journal_line_id
        and journal_lines.source_relation = pivoted_tracking_categories.source_relation
        and journals.journal_id = pivoted_tracking_categories.journal_id
        and journals.source_relation = pivoted_tracking_categories.source_relation
    {% endif %}

)

select *
from joined
