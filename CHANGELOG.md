# dbt_xero v0.6.2
[PR #46](https://github.com/fivetran/dbt_xero/pull/46) includes the following updates:

## Bug Fixes
- Update to the `xero__balance_sheet` model to ensure the calculated `current_year_end_date` field takes into account fiscal year ends which occur in a leap year. To address this, if a lookback is required, then February 28th of the previous year will be used to ensure an valid date is used.

## Under the Hood
- Included auto-releaser GitHub Actions workflow to automate future releases.
- Updated the maintainer PR template to resemble the most up to date format.

# dbt_xero v0.6.1

[PR #40](https://github.com/fivetran/dbt_xero/pull/40) includes the following updates:

## Test Updates
- The unique combination of columns test within the `xero__general_ledger` model has been updated to include `journal_id` in addition to `journal_line_id` and `source_relation`. 
  - This update is required as deleted journals may still appropriately be rendered in the general ledger; however, they will have no associated journal lines. As such, there may be unique `journal_id`s with a null `journal_line_id`. This test update will account for this scenario.

## Contributors
- [@jsagasta](https://github.com/jsagasta) ([PR #40](https://github.com/fivetran/dbt_xero/pull/40))

# dbt_xero v0.6.0
## 🎉 Feature Update 🎉
- Databricks compatibility! ([#38](https://github.com/fivetran/dbt_xero/pull/38))

## 🚘 Under the Hood 🚘
- Incorporated the new `fivetran_utils.drop_schemas_automation` macro into the end of each Buildkite integration test job. ([#37](https://github.com/fivetran/dbt_xero/pull/37))
- Updated the pull request [templates](/.github). ([#37](https://github.com/fivetran/dbt_xero/pull/37))

# dbt_xero v0.5.0

## 🚨 Breaking Changes 🚨:
[PR #33](https://github.com/fivetran/dbt_xero/pull/33) includes the following breaking changes:
- Dispatch update for dbt-utils to dbt-core cross-db macros migration. Specifically `{{ dbt_utils.<macro> }}` have been updated to `{{ dbt.<macro> }}` for the below macros:
    - `any_value`
    - `bool_or`
    - `cast_bool_to_text`
    - `concat`
    - `date_trunc`
    - `dateadd`
    - `datediff`
    - `escape_single_quotes`
    - `except`
    - `hash`
    - `intersect`
    - `last_day`
    - `length`
    - `listagg`
    - `position`
    - `replace`
    - `right`
    - `safe_cast`
    - `split_part`
    - `string_literal`
    - `type_bigint`
    - `type_float`
    - `type_int`
    - `type_numeric`
    - `type_string`
    - `type_timestamp`
    - `array_append`
    - `array_concat`
    - `array_construct`
- For `current_timestamp` and `current_timestamp_in_utc` macros, the dispatch AND the macro names have been updated to the below, respectively:
    - `dbt.current_timestamp_backcompat`
    - `dbt.current_timestamp_in_utc_backcompat`
- Dependencies on `fivetran/fivetran_utils` have been upgraded, previously `[">=0.3.0", "<0.4.0"]` now `[">=0.4.0", "<0.5.0"]`.

# dbt_xero v0.4.2
## Bug Fix
- Fixes duplicate values in `net_amount` field in `xero__balance_sheet_report` when leveraging logic to union multiple Xero connectors
## Contributors
- [@danieltaft](https://github.com/danieltaft)[#30](https://github.com/fivetran/dbt_xero/pull/30)

# dbt_xero v0.4.1
## Features
- Adds the `xero__using_bank_transaction` variable to disable the associated models on instances of Xero that don't include the `bank_transaction` source table. ([#27](https://github.com/fivetran/dbt_xero/pull/27))

## Contributors
- [@santi95](https://github.com/santi95) ([#27](https://github.com/fivetran/dbt_xero/pull/27))

# dbt_xero v0.4.0
🎉 dbt v1.0.0 Compatibility 🎉
## 🚨 Breaking Changes 🚨
- Adjusts the `require-dbt-version` to now be within the range [">=1.0.0", "<2.0.0"]. Additionally, the package has been updated for dbt v1.0.0 compatibility. If you are using a dbt version <1.0.0, you will need to upgrade in order to leverage the latest version of the package.
  - For help upgrading your package, I recommend reviewing this GitHub repo's Release Notes on what changes have been implemented since your last upgrade.
  - For help upgrading your dbt project to dbt v1.0.0, I recommend reviewing dbt-labs [upgrading to 1.0.0 docs](https://docs.getdbt.com/docs/guides/migration-guide/upgrading-to-1-0-0) for more details on what changes must be made.
- Upgrades the package dependency to refer to the latest `dbt_xero_source`. Additionally, the latest `dbt_xero_source` package has a dependency on the latest `dbt_fivetran_utils`. Further, the latest `dbt_fivetran_utils` package also has a dependency on `dbt_utils` [">=0.8.0", "<0.9.0"].
  - Please note, if you are installing a version of `dbt_utils` in your `packages.yml` that is not in the range above then you will encounter a package dependency error.

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
