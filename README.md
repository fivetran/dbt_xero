<p align="center">
    <a alt="License"
        href="https://github.com/fivetran/dbt_xero/blob/main/LICENSE">
        <img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg" /></a>
    <a alt="dbt-core">
        <img src="https://img.shields.io/badge/dbt_Core™_version->=1.3.0_,<2.0.0-orange.svg" /></a>
    <a alt="Maintained?">
        <img src="https://img.shields.io/badge/Maintained%3F-yes-green.svg" /></a>
    <a alt="PRs">
        <img src="https://img.shields.io/badge/Contributions-welcome-blueviolet" /></a>
</p>

# Xero Transformation dbt Package ([Docs](https://fivetran.github.io/dbt_xero/))
## What does this dbt package do?
- Produces modeled tables that leverage Xero data from [Fivetran's connector](https://fivetran.com/docs/applications/xero) in the format described by [this ERD](https://fivetran.com/docs/applications/xero#schemainformation) and builds off the output of our [Xero source package](https://github.com/fivetran/dbt_xero_source).

- Provides analytics-ready models, including a profit and loss report, general ledger, and balance sheet report.
- Generates a comprehensive data dictionary of your source and modeled Xero data through the [dbt docs site](https://fivetran.github.io/dbt_xero/).

The following table provides a detailed list of all models materialized within this package by default.

| **Model**                | **Description**                                                                                      |
| ----------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| [xero__general_ledger](https://github.com/fivetran/dbt_xero/blob/main/models/xero__general_ledger.sql)          | Each record represents a journal line item. Use the ledger to create the balance sheet and the profit and loss statement. |
| [xero__profit_and_loss_report](https://github.com/fivetran/dbt_xero/blob/main/models/xero__profit_and_loss_report.sql)  | Each record represents a profit and loss line item at the month and account level.                                     |
| [xero__balance_sheet_report](https://github.com/fivetran/dbt_xero/blob/main/models/xero__balance_sheet_report.sql)    | Each record represents the state of the balance sheet for a given account on a given month.                            |
| [xero__invoice_line_items](https://github.com/fivetran/dbt_xero/blob/main/models/xero__invoice_line_items.sql)      | Each record represents an invoice line item enriched with the account, contact, and invoice information.                   |

## How do I use the dbt package?

### Step 1: Prerequisites
To use this dbt package, you must have the following:

- At least one Fivetran Xero connector syncing data into your destination.
- A **BigQuery**, **Snowflake**, **Redshift**, **PostgreSQL**, or **Databricks** destination.

### Step 2: Install the package
Include the following xero package version in your `packages.yml` file:
> TIP: Check [dbt Hub](https://hub.getdbt.com/) for the latest installation instructions or [read the dbt docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.
```yaml
packages:
  - package: fivetran/xero
    version: [">=0.6.0", "<0.7.0"] # we recommend using ranges to capture non-breaking changes automatically
```
Do NOT include the `xero_source` package in this file. The transformation package itself has a dependency on it and will install the source package as well.
### Step 3: Define database and schema variables
By default, this package runs using your destination and the `xero` schema. If this is not where your Xero data is (for example, if your Xero schema is named `xero_fivetran`), add the following configuration to your root `dbt_project.yml` file:

```yml
vars:
    xero_schema: your_schema_name
    xero_database: your_database_name 
```

### (Optional) Step 4: Additional configurations

#### Note about currency gains

If you are using multi-currency accounting in Xero, you are likely to have unrealized currency gains as part of your profit and loss statement. These gains/losses do not exist within the actual journals in Xero. As a result, you will find that those lines are missing from the outputs of this package. All realised currency gains will be present and your balance sheet will still balance.

#### Unioning Multiple Xero Connectors
If you have multiple Xero connectors in Fivetran and would like to use this package on all of them simultaneously, we have provided functionality to do so. The package will union all of the data together and pass the unioned table into the transformations. You will be able to see which source it came from in the `source_relation` column of each model. To use this functionality, you will need to set **either** (**note that you cannot use both**) the `union_schemas` or `union_databases` variables:

```yml
# dbt_project.yml
...
config-version: 2
vars:
  xero_source:
    union_schemas: ['xero_us','xero_ca'] # use this if the data is in different schemas/datasets of the same database/project
    union_databases: ['xero_us','xero_ca'] # use this if the data is in different databases/projects but uses the same schema name
```

#### Disabling and Enabling Models

When setting up your Xero connection in Fivetran, it is possible that not every table this package expects will be synced. This can occur because you either don't use that functionality in Xero or have actively decided to not sync some tables. In order to disable the relevant functionality in the package, you will need to add the relevant variables.

By default, all variables are assumed to be `true`. You only need to add variables for the tables you would like to disable:

```yml
# dbt_project.yml

config-version: 2

vars:
    xero__using_credit_note: false                      # default is true
    xero__using_bank_transaction: false                 # default is true
```

For additional configurations for the source models, visit the [Xero source package](https://github.com/fivetran/dbt_xero_source).

#### Changing the Build Schema
By default this package will build the Xero Source staging models within a schema titled (<target_schema> + `_stg_xero`) and the Xero final transform models within a schema titled (<target_schema> + `_xero`) in your target database.
To overwrite this behavior, add the following configuration to your `dbt_project.yml` file:

```yml
# dbt_project.yml

...
models:
    xero:
        +schema: my_new_final_models_schema # leave blank for just the target_schema
    xero_source:
        +schema: my_new_staging_models_schema # leave blank for just the target_schema

```
#### Change the source table references
If an individual source table has a different name than the package expects, add the table name as it appears in your destination to the respective variable:

> IMPORTANT: See this project's [`dbt_project.yml`](https://github.com/fivetran/dbt_xero/blob/main/dbt_project.yml) variable declarations to see the expected names.

```yml
vars:
    xero_<default_source_table_name>_identifier: your_table_name 
```

</details>

### (Optional) Step 5: Orchestrate your models with Fivetran Transformations for dbt Core™

Fivetran offers the ability for you to orchestrate your dbt project through [Fivetran Transformations for dbt Core™](https://fivetran.com/docs/transformations/dbt). Learn how to set up your project for orchestration through Fivetran in our [Transformations for dbt Core setup guides](https://fivetran.com/docs/transformations/dbt#setupguide).

</details>

## Does this package have dependencies?
This dbt package is dependent on the following dbt packages. These dependencies are installed by default within this package. For more information on the following packages, refer to the [dbt hub](https://hub.getdbt.com/) site.
> IMPORTANT: If you have any of these dependent packages in your own `packages.yml` file, we highly recommend that you remove them from your root `packages.yml` to avoid package version conflicts.
    
```yml
packages:
    - package: fivetran/dbt_xero_source
      version: [">=0.6.0", "<0.7.0"]

    - package: fivetran/fivetran_utils
      version: [">=0.4.0", "<0.5.0"]

    - package: dbt-labs/dbt_utils
      version: [">=1.0.0", "<2.0.0"]
```
## How is this package maintained and can I contribute?
### Package Maintenance
The Fivetran team maintaining this package _only_ maintains the latest version of the package. We highly recommend you stay consistent with the [latest version](https://hub.getdbt.com/fivetran/xero/latest/) of the package and refer to the [CHANGELOG](https://github.com/fivetran/dbt_xero/blob/main/CHANGELOG.md) and release notes for more information on changes across versions.

### Contributions
A small team of analytics engineers at Fivetran develops these dbt packages. However, the packages are made better by community contributions.

We highly encourage and welcome contributions to this package. Check out [this dbt Discourse article](https://discourse.getdbt.com/t/contributing-to-a-dbt-package/657) on the best workflow for contributing to a package.

## Are there any resources available?
- If you have questions or want to reach out for help, see the [GitHub Issue](https://github.com/fivetran/dbt_xero/issues/new/choose) section to find the right avenue of support for you.
- If you would like to provide feedback to the dbt package team at Fivetran or would like to request a new dbt package, fill out our [Feedback Form](https://www.surveymonkey.com/r/DQ7K7WW).
