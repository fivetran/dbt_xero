<p align="center">
    <a alt="License"
        href="https://github.com/fivetran/dbt_xero/blob/main/LICENSE">
        <img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg" /></a>
    <a alt="Fivetran-Release"
        href="https://fivetran.com/docs/getting-started/core-concepts#releasephases">
        <img src="https://img.shields.io/badge/Fivetran Release Phase-_Beta-orange.svg" /></a>
    <a alt="dbt-core">
        <img src="https://img.shields.io/badge/dbt_core-version_>=1.0.0_<2.0.0-orange.svg" /></a>
    <a alt="Maintained?">
        <img src="https://img.shields.io/badge/Maintained%3F-yes-green.svg" /></a>
    <a alt="PRs">
        <img src="https://img.shields.io/badge/Contributions-welcome-blueviolet" /></a>
</p>

# Xero Modeling dbt Package ([Docs](https://fivetran.github.io/dbt_xero/))
# 📣 What does this dbt package do?
- Produces modeled tables that leverage Xero data from [Fivetran's connector](https://fivetran.com/docs/applications/xero) in the format described by [this ERD](https://fivetran.com/docs/applications/xero#schemainformation) and builds off the output of our [Xero source package](https://github.com/fivetran/dbt_xero_source).
- The primary focus is to transform the core tables into analytics-ready models, including a:
    - Profit and Loss report
    - General Ledger 
    - Balance Sheet report.
- Generates a comprehensive data dictionary of your source and modeled Xero data via the [dbt docs site](https://fivetran.github.io/dbt_xero/)

Refer to the table below for a detailed view of all models materialized by default within this package. Additionally, check out our [docs site](https://fivetran.github.io/dbt_xero/#!/overview?g_v=1) for more details about these models. 
| **model**                     | **description**                                                                                                        |
| ----------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| [xero__general_ledger](https://fivetran.github.io/dbt_xero/#!/model/model.xero.xero__general_ledger)          | Each record represents a journal line item. Use the ledger to create the balance sheet and the profit and loss statement. |
| [xero__profit_and_loss_report](https://fivetran.github.io/dbt_xero/#!/model/model.xero.xero__profit_and_loss_report)  | Each record represents a profit and loss line item at the month and account level.                                     |
| [xero__balance_sheet_report](https://fivetran.github.io/dbt_xero/#!/model/model.xero.xero__balance_sheet_report)    | Each record represents the state of the balance sheet for a given account on a given month.                            |
| [xero__invoice_line_items](https://fivetran.github.io/dbt_xero/#!/model/model.xero.xero__invoice_line_items)      | Each record represents an invoice line item enriched with the account, contact, and invoice information.                   |
# 🤔 Who is the target user of this dbt package?
- You use Fivetran's [Xero connector](https://fivetran.com/docs/applications/xero)
- You use dbt
- You want a staging layer that cleans, tests, and prepares your xero data for analysis as well as leverage the analysis ready models outlined above.
# 🎯 How do I use the dbt package?
To effectively install this package and leverage the pre-made models, you will follow the below steps:
## Step 1: Pre-Requisites
You will need to ensure you have the following before leveraging the dbt package.
- **Connector**: Have the Fivetran xero connector syncing data into your warehouse. 
- **Database support**: This package has been tested on **BigQuery**, **Snowflake**, **Redshift**, and **Postgres**. Ensure you are using one of these supported databases.
- **dbt Version**: This dbt package requires you have a functional dbt project that utilizes a dbt version within the respective range `>=1.0.0, <2.0.0`.
## Step 2: Installing the Package
Include the following xero_source package version in your `packages.yml`
> Check [dbt Hub](https://hub.getdbt.com/) for the latest installation instructions, or [read the dbt docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.
```yaml
packages:
  - package: fivetran/xero
    version: [">=0.5.0", "<0.6.0"]

```
## Step 3: Configure Your Variables
### Database and Schema Variables
By default, this package will run using your target database and the `xero` schema. If this is not where your xero data is (perhaps your xero schema is `xero_fivetran` and your `issue` table is named `usa_issue`), add the following configuration to your root `dbt_project.yml` file:

```yml
vars:
    xero_database: your_database_name
    xero_schema: your_schema_name 
    xero__<default_source_table_name>_identifier: your_table_name
```
### Unioning Multiple Xero Connectors
If you have multiple Xero connectors in Fivetran and would like to use this package on all of them simultaneously, we have provided functionality to do so. The package will union all of the data together and pass the unioned table into the transformations. You will be able to see which source it came from in the `source_relation` column of each model. To use this functionality, you will need to set **either** (**note that you cannot use both**) the `union_schemas` or `union_databases` variables:
```yml
vars:
    xero_union_schemas: ['xero_us','xero_ca'] # use this if the data is in different schemas/datasets of the same database/project
    xero_union_databases: ['xero_us','xero_ca'] # use this if the data is in different databases/projects but uses the same schema name
```

### Disabling Components
Your Xero connector might not sync every table that this package expects. If you do not have the `credit_note` or `bank_transaction` tables synced, add the following variable to your root `dbt_project.yml` file:

```yml
vars:
    xero__using_credit_note: false                  # default is true
    xero__using_bank_transaction: false             # default is true
```

## (Optional) Step 4: Additional Configurations
### Change the Build Schema
By default, this package builds the Xero staging models within a schema titled (<target_schema> + _stg_xero) and your xero modeling models within a schema titled (<target_schema> + _xero) in your target database. If this is not where you would like your xero data to be written to, add the following configuration to your root `dbt_project.yml` file:

```yml
models:
    xero_source:
      +schema: my_new_schema_name # leave blank for just the target_schema
    xero:
      +schema: my_new_schema_name # leave blank for just the target_schema
```

## Step 5: Finish Setup
Your dbt project is now setup to successfully run the dbt package models! You can now execute `dbt run` and `dbt test` to have the models materialize in your warehouse and execute the data integrity tests applied within the package.

## (Optional) Step 6: Orchestrate your package models with Fivetran
Fivetran offers the ability for you to orchestrate your dbt project through the [Fivetran Transformations for dbt Core](https://fivetran.com/docs/transformations/dbt) product. Refer to the linked docs for more information on how to setup your project for orchestration through Fivetran. 

# 🔍 Does this package have dependencies?
This dbt package is dependent on the following dbt packages. For more information on the below packages, refer to the [dbt hub](https://hub.getdbt.com/) site.
> **If you have any of these dependent packages in your own `packages.yml` I highly recommend you remove them to ensure there are no package version conflicts.**
```yml
packages:
    - package: fivetran/xero_source
      version: [">=0.5.0", "<0.6.0"]

    - package: fivetran/fivetran_utils
      version: [">=0.3.0", "<0.4.0"]

    - package: dbt-labs/dbt_utils
      version: [">=0.8.0", "<0.9.0"]
```
# 🙌 How is this package maintained and can I contribute?
## Package Maintenance
The Fivetran team maintaining this package **only** maintains the latest version of the package. We highly recommend you stay consistent with the [latest version](https://hub.getdbt.com/fivetran/xero/latest/) of the package and refer to the [CHANGELOG](https://github.com/fivetran/dbt_xero/blob/main/CHANGELOG.md) and release notes for more information on changes across versions.

## Contributions
These dbt packages are developed by a small team of analytics engineers at Fivetran. However, the packages are made better by community contributions! 

We highly encourage and welcome contributions to this package. Check out [this post](https://discourse.getdbt.com/t/contributing-to-a-dbt-package/657) on the best workflow for contributing to a package!

# 🏪 Are there any resources available?
- If you encounter any questions or want to reach out for help, please refer to the [GitHub Issue](https://github.com/fivetran/dbt_xero/issues/new/choose) section to find the right avenue of support for you.
- If you would like to provide feedback to the dbt package team at Fivetran, or would like to request a future dbt package to be developed, then feel free to fill out our [Feedback Form](https://www.surveymonkey.com/r/DQ7K7WW).
- Have questions or want to just say hi? Book a time during our office hours [here](https://calendly.com/fivetran-solutions-team/fivetran-solutions-team-office-hours) or send us an email at solutions@fivetran.com.
