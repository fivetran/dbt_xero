with stg_BankTransactions as (
    select 
 *
    from {{ ref('stg_xero__bank_transaction') }}
), 

AggregatedData as (
    select
        {{ dbt_utils.generate_surrogate_key(['AccountID','AccountID']) }} as account_key,
        {{ dbt_utils.generate_surrogate_key(['ContactID','ContactID']) }} AS ContactKey,
        {{ convert_timestamp_str_to_date_tsql('bt.TransactionDate') }} AS Date ,
        case
            when bt.TransactionType in ('SPEND','SPEND-TRANSFER') then (bt.TotalAmount / bt.CurrencyRate )* -1 
            when bt.TransactionType in ('RECEIVE','RECEIVE-TRANSFER') then bt.TotalAmount / bt.CurrencyRate 
            else bt.TotalAmount / bt.CurrencyRate 
        end as amount,

        bt.BankTransactionID,
        bt.BankAccountName,
        bt.TransactionType,
        bt.TransactionStatus,
        bt.IsReconciled,
        bt.CurrencyCode,
        bt.SubTotal,
        bt.TotalTax,
        bt.Reference,
        bt.CurrencyRate,
         'BANK TRANSACTION' as source

    from stg_BankTransactions bt

    where TransactionStatus LIKE 'AUTHORISED'
)

select * from AggregatedData
