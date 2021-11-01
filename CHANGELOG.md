# dbt_xero v0.3.0

## Features
- Allow for multiple sources by unioning source tables across multiple Xero connectors.
([#11](https://github.com/fivetran/dbt_xero_source/pull/11))
  - Refer to the README for more details. (See ### Unioning Multiple Xero Connectors).

## Under the Hood
- Unioning: The unioning occurs in Xero source package using the `fivetran_utils.union_data` macro.
- Unique tests: Because columns that were previously used for unique tests may now have duplicate fields across multiple sources, these columns are combined with the new `source_relation` column for unique tests and tested using the `dbt_utils.unique_combination_of_columns` macro. 
- Source Relation column: To distinguish which source each field comes from, we added a new `source_relation` column in each staging model and applied the `fivetran_utils.source_relation` macro.

