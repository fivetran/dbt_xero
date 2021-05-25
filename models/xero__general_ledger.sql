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
    from {{ ref('stg_xero__invoice') }}

), bank_transactions as (

    select *
    from {{ ref('stg_xero__bank_transaction') }}

), credit_notes as (

    select *
    from {{ ref('stg_xero__credit_note') }}

), joined as (

    select 
        journals.journal_id,
        journals.created_date_utc,
        journals.journal_date,
        journals.journal_number,
        journals.reference,
        journals.source_id,
        journals.source_type,

        journal_lines.journal_line_id,
        journal_lines.account_code,
        journal_lines.account_id,
        journal_lines.account_name,
        journal_lines.account_type,
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

    from journals
    left join journal_lines
        on journals.journal_id = journal_lines.journal_id
    left join accounts
        on accounts.account_id = journal_lines.account_id

), contacts as (

    select 
        joined.*,
        coalesce(
            invoices.contact_id,
            bank_transactions.contact_id,
            credit_notes.contact_id
        ) as contact_id
    from joined
    left join invoices
        using (invoice_id)
    left join bank_transactions
        using (bank_transaction_id)
    left join credit_notes
        using (credit_note_id)

)

select *
from contacts 