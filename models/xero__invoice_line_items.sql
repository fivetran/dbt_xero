with line_items as (

    select *
    from {{ var('invoice_line_item') }}

), invoices as (

    select *
    from {{ var('invoice') }}

), accounts as (

    select *
    from {{ var('account') }}

), contacts as (

    select *
    from {{ var('contact') }}

), joined as (

    select
        line_items.*,

        invoices.invoice_date,
        invoices.updated_date,
        invoices.planned_payment_date,
        invoices.due_date,
        invoices.expected_payment_date,
        invoices.fully_paid_on_date,
        invoices.currency_code,
        invoices.currency_rate,
        invoices.invoice_number,
        invoices.is_sent_to_contact,
        invoices.invoice_status,
        invoices.type,
        invoices.url,
        invoices.reference as invoice_reference,

        accounts.account_id,
        accounts.account_name,
        accounts.account_type,
        accounts.account_class,

        contacts.contact_name

    from line_items
    left join invoices
        using (invoice_id)
    left join accounts
        using (account_code)
    left join contacts
        using (contact_id)

)

select *
from joined