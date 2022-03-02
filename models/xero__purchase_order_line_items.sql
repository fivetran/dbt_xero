with line_items as (

    select *
    from {{ var('purchase_order_line_item') }}

), purchase_orders as (

    select *
    from {{ var('purchase_order') }}

), accounts as (

    select *
    from {{ var('account') }}

), contacts as (

    select *
    from {{ var('contact') }}

), joined as (

    select
        line_items.*,

        purchase_orders.purchase_order_date,
        purchase_orders.updated_date,
        purchase_orders.delivery_date,
        purchase_orders.sub_total,
        purchase_orders.total_tax,
        purchase_orders.total,
        purchase_orders.currency_code,
        purchase_orders.currency_rate,
        purchase_orders.purchase_order_number,
        purchase_orders.purchase_order_status,
        purchase_orders.type,
        purchase_orders.reference as purchase_order_reference,
        purchase_orders.is_discounted,
        purchase_orders.line_amount_types,
        accounts.account_id,
        accounts.account_name,
        accounts.account_type,
        accounts.account_class,

        contacts.contact_name

    from line_items
    left join purchase_orders
        on (line_items.purchase_order_id = purchase_orders.purchase_order_id
        and line_items.source_relation = purchase_orders.source_relation)
    left join accounts
        on (line_items.account_code = accounts.account_code
        and line_items.source_relation = accounts.source_relation)
    left join contacts
        on (purchase_orders.contact_id = contacts.contact_id
        and purchase_orders.source_relation = contacts.source_relation)

)

select *
from joined