{%- set using_tracking_categories = (
    var('xero__using_journal_line_tracking_category', True)
    and var('xero__using_tracking_categories', True)
) -%}

{% set pivoted_columns_prefixed = [] %}
{% if using_tracking_categories %}
    {% set pivoted_columns_prefixed = get_prefixed_tracking_category_columns(
        model_name='int_xero__journal_line_pivoted_tracking_categories',
        id_fields=['journal_id', 'journal_line_id', 'source_relation']
    ) %}
{% endif %}

with journals as (

    select *
    from {{ var('journal') }}

), journal_lines as (

    select *
    from {{ var('journal_line') }}

), accounts as (

    select *
    from {{ var('account') }}

), invoices as (

    select *
    from {{ var('invoice') }}

{% if var('xero__using_bank_transaction', True) %}
), bank_transactions as (

    select *
    from {{ var('bank_transaction') }}

{% endif %}

{% if var('xero__using_credit_note', True) %}
), credit_notes as (

    select *
    from {{ var('credit_note') }}
{% endif %}

), contacts as (

    select *
    from {{ var('contact') }}

{% if using_tracking_categories %}
), pivoted_tracking_categories as (

    select *
    from {{ ref('int_xero__journal_line_pivoted_tracking_categories') }}
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

        case when journals.source_type in ('ACCPAY', 'ACCREC') then journals.source_id end as invoice_id,
        case when journals.source_type in ('CASHREC','CASHPAID') then journals.source_id end as bank_transaction_id,
        case when journals.source_type in ('TRANSFER') then journals.source_id end as bank_transfer_id,
        case when journals.source_type in ('MANJOURNAL') then journals.source_id end as manual_journal_id,
        case when journals.source_type in ('APPREPAYMENT', 'APOVERPAYMENT', 'ACCPAYPAYMENT', 'ACCRECPAYMENT', 'ARCREDITPAYMENT', 'APCREDITPAYMENT') then journals.source_id end as payment_id,
        case when journals.source_type in ('ACCPAYCREDIT','ACCRECCREDIT') then journals.source_id end as credit_note_id

        {% if using_tracking_categories and pivoted_columns_prefixed|length > 0 %}
        -- Pivoted tracking categories, excluding duplicate columns
        {% for col in pivoted_columns_prefixed %}
        , {{ col }} 
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
        and journals.journal_id = pivoted_tracking_categories.journal_id
        and journals.source_relation = pivoted_tracking_categories.source_relation
    {% endif %}

), first_contact as (

    select 
        joined.*,
        {% if fivetran_utils.enabled_vars_one_true(['xero__using_bank_transaction','xero__using_credit_note']) %}
        coalesce(
            invoices.contact_id
            {% if var('xero__using_bank_transaction', True) %}
                , bank_transactions.contact_id
            {% endif %}

            {% if var('xero__using_credit_note', True) %}
            , credit_notes.contact_id
            {% endif %}
        )
        {% else %}
        invoices.contact_id
        {% endif %}

        as contact_id
    from joined
    left join invoices 
        on (joined.invoice_id = invoices.invoice_id
        and joined.source_relation = invoices.source_relation)
    {% if var('xero__using_bank_transaction', True) %}
    left join bank_transactions
        on (joined.bank_transaction_id = bank_transactions.bank_transaction_id
        and joined.source_relation = bank_transactions.source_relation)
    {% endif %}

    {% if var('xero__using_credit_note', True) %}
    left join credit_notes 
        on (joined.credit_note_id = credit_notes.credit_note_id
        and joined.source_relation = credit_notes.source_relation)
    {% endif %}

), second_contact as (

    select 
        first_contact.*,
        contacts.contact_name
    from first_contact
    left join contacts 
        on (first_contact.contact_id = contacts.contact_id
        and first_contact.source_relation = contacts.source_relation)

)

select *
from second_contact