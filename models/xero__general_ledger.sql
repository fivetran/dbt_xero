with journals as (

    select *
    from {{ ref('stg_xero__journal') }}

), journal_lines as (

    select *
    from {{ ref('stg_xero__journal_line') }}

), accounts as (

    select *
    from {{ ref('stg_xero__account') }}

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

        accounts.account_class  
    from journals
    left join journal_lines
        on journals.journal_id = journal_lines.journal_id
    left join accounts
        on accounts.account_id = journal_lines.account_id

)

select *
from joined 