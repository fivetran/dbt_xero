with journals as (

    select *
    from {{ ref('stg_xero__journal') }}

), journal_lines as (

    select *
    from {{ ref('stg_xero__journal_line') }}

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

        case when journal_lines.net_amount < 0 then abs(journal_lines.net_amount) end as credit,
        case when journal_lines.net_amount >= 0 then abs(journal_lines.net_amount) end as debit
    from journals
    left join journal_lines
        on journals.journal_id = journal_lines.journal_id

)

select *
from joined 