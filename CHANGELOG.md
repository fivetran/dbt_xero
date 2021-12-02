# dbt_xero v0.3.1
## Bug Fix
- The `account_code`, `account_id`, `account_name`, and `account_type` fields within the `xero_general_ledger` are now being selected from the `stg_xero__account` model instead of the `stg_xero__journal_line` model. 
  - It was found that account names may be changed within Xero, but the account name within a journal line entry will remain the old name. As such, this fix will ensure all records on the `xero__general_ledger` and downstream models reflect the most up to date name of the account.

# dbt_xero v0.3.0

## Features
- Allow for multiple sources by unioning source tables across multiple Xero connectors.
([#11](https://github.com/fivetran/dbt_xero_source/pull/11))
  - Refer to the unioning multiple Xero connectors section of the [README](https://github.com/fivetran/dbt_xero/tree/main#unioning-multiple-xero-connectors) for more details.

## Under the Hood
- Unioning: The unioning occurs in Xero source package using the `fivetran_utils.union_data` macro. ([#16](https://github.com/fivetran/dbt_xero/pull/16))
- Unique tests: Because columns that were previously used for unique tests may now have duplicate fields across multiple sources, these columns are combined with the new `source_relation` column for unique tests and tested using the `dbt_utils.unique_combination_of_columns` macro. ([#16](https://github.com/fivetran/dbt_xero/pull/16))
- Source Relation column: To distinguish which source each field comes from, we added a new `source_relation` column in each staging model and applied the `fivetran_utils.source_relation` macro. ([#16](https://github.com/fivetran/dbt_xero/pull/16))
- Utils Materialization: We have made the default materialization of the `utils` folder to be ephemeral. ([#16](https://github.com/fivetran/dbt_xero/pull/16))

# dbt_xero v0.1.0 -> v0.2.0
Refer to the relevant release notes on the Github repository for specific details for the previous releases. Thank you!