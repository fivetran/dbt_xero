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

), tracking_categories as (
    
    select *
    from {{ ref('int_xero__invoice_line_item_tracking_categories') }}

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

        contacts.contact_name,

        tracking_categories.tracking_category_1,
        tracking_categories.tracking_category_2

    from line_items
    left join invoices
        on (line_items.invoice_id = invoices.invoice_id
        and line_items.source_relation = invoices.source_relation)
    left join accounts
        on (line_items.account_code = accounts.account_code
        and line_items.source_relation = accounts.source_relation)
    left join contacts
        on (invoices.contact_id = contacts.contact_id
        and invoices.source_relation = contacts.source_relation)
    left join tracking_categories
        on line_items.line_item_id = tracking_categories.line_item_id
        and line_items.source_relation = tracking_categories.source_relation
)

select *
from joined