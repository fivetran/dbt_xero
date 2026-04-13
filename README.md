<!--section="xero_transformation_model"-->
# Xero dbt Package 

This dbt package transforms data from Fivetran's Xero connector into analytics-ready tables.

## Resources

- Number of materialized models¹: 35
- Connector documentation
  - [Xero connector documentation](https://fivetran.com/docs/connectors/applications/xero)
  - [Xero ERD](https://fivetran.com/docs/connectors/applications/xero#schemainformation)
- dbt package documentation
  - [GitHub repository](https://github.com/fivetran/dbt_xero)
  - [dbt Docs](https://fivetran.github.io/dbt_xero/#!/overview)
  - [DAG](https://fivetran.github.io/dbt_xero/#!/overview?g_v=1)
  - [Changelog](https://github.com/fivetran/dbt_xero/blob/main/CHANGELOG.md)
- dbt Core™ supported versions
  - `>=1.3.0, <3.0.0`

## What does this dbt package do?
This package enables you to produce modeled tables, provide analytics-ready models, and generate comprehensive data dictionaries. It creates enriched models with metrics focused on profit and loss reports, general ledgers, and balance sheet reports.

> Note: Currently, our dbt models for Xero have limited support for multi-currency accounting, particularly for handling unrealized currency gains and losses and bank revaluations, as they require historical or current exchange rate data that is not available in the Xero connector to fully calculate.

### Output schema
Final output tables are generated in the following target schema:

```
<your_database>.<connector/schema_name>_xero
```

### Final output tables

By default, this package materializes the following final tables:

| Table | Description |
| :---- | :---- |
| [xero__general_ledger](https://github.com/fivetran/dbt_xero/blob/main/models/xero__general_ledger.sql) | Tracks every journal line item with debits, credits, and account classifications to provide a complete transaction history for building financial statements and analyzing account activity. <br></br>**Example Analytics Questions:**<ul><li>What is the total net amount by account class (asset, liability, equity, revenue, expense) for a given period?</li><li>Which accounts have the highest transaction volumes or largest balance changes?</li><li>How do journal entries by source type (invoice, payment, manual) contribute to overall financial activity?</li></ul>|
| [xero__profit_and_loss_report](https://github.com/fivetran/dbt_xero/blob/main/models/xero__profit_and_loss_report.sql) | Summarizes monthly profit and loss by account with net amounts to track revenue, expenses, and profitability trends over time at the account level. <br></br>**Example Analytics Questions:**<ul><li>What are monthly revenue and expense trends by account class (revenue vs expense)?</li><li>Which expense accounts are growing fastest month-over-month?</li><li>What is the net profit or loss for each month across all revenue and expense accounts?</li></ul>|
| [xero__balance_sheet_report](https://github.com/fivetran/dbt_xero/blob/main/models/xero__balance_sheet_report.sql) | Shows the monthly balance sheet position for each account to track assets, liabilities, and equity over time and understand financial health. <br></br>**Example Analytics Questions:**<ul><li>What is the current balance for each asset, liability, and equity account?</li><li>How have account balances changed month-over-month across different account classes?</li><li>What is the total asset value versus total liability value for each reporting period?</li></ul>|
| [xero__invoice_line_items](https://github.com/fivetran/dbt_xero/blob/main/models/xero__invoice_line_items.sql) | Provides detailed invoice line item data enriched with account, contact, and invoice information including amounts, taxes, and payment status to analyze billing and revenue. <br></br>**Example Analytics Questions:**<ul><li>Which customers or contacts generate the highest invoice amounts and line item volumes?</li><li>What are the most common products or services sold based on line item descriptions?</li><li>How do discount rates and tax amounts vary across different invoice line items or customers?</li></ul>|

¹ Each Quickstart transformation job run materializes these models if all components of this data model are enabled. This count includes all staging, intermediate, and final models materialized as `view`, `table`, or `incremental`.

---

## Prerequisites
To use this dbt package, you must have the following:

- At least one Fivetran Xero connection syncing data into your destination.
- A **BigQuery**, **Snowflake**, **Redshift**, **PostgreSQL**, or **Databricks** destination.

## How do I use the dbt package?
You can either add this dbt package in the Fivetran dashboard or import it into your dbt project:

- To add the package in the Fivetran dashboard, follow our [Quickstart guide](https://fivetran.com/docs/transformations/data-models/quickstart-management).
- To add the package to your dbt project, follow the setup instructions in the dbt package's [README file](https://github.com/fivetran/dbt_xero/blob/main/README.md#how-do-i-use-the-dbt-package) to use this package.

<!--section-end-->

### Install the package
Include the following xero package version in your `packages.yml` file:
> TIP: Check [dbt Hub](https://hub.getdbt.com/) for the latest installation instructions or [read the dbt docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.
```yaml
packages:
  - package: fivetran/xero
    version: [">=1.3.0", "<1.4.0"] # we recommend using ranges to capture non-breaking changes automatically
```
> All required sources and staging models are now bundled into this transformation package. Do not include `fivetran/xero_source` in your `packages.yml` since this package has been deprecated.

#### Option A: Single connection
By default, this package runs using your destination and the `xero` schema. If this is not where your Xero data is (for example, if your Xero schema is named `xero_fivetran`), add the following configuration to your root `dbt_project.yml` file:

```yml
vars:
    xero_database: your_destination_name
    xero_schema: your_schema_name
```

#### Option B: Union multiple connections
If you have multiple Xero connections in Fivetran and would like to use this package on all of them simultaneously, we have provided functionality to do so. For each source table, the package will union all of the data together and pass the unioned table into the transformations. The `source_relation` column in each model indicates the origin of each record.

To use this functionality, you will need to set the `xero_sources` variable in your root `dbt_project.yml` file:

```yml
# dbt_project.yml

vars:
  xero:
    xero_sources:
      - database: connection_1_destination_name # Required
        schema: connection_1_schema_name # Required
        name: connection_1_source_name # Required only if following the step in the following subsection

      - database: connection_2_destination_name
        schema: connection_2_schema_name
        name: connection_2_source_name
```

> Previous versions of this package employed two separate, mutually exclusive variables for unioning: `union_schemas` and `union_databases`. While these variables are still supported, `xero_sources` is the recommended variable to configure.

##### Recommended: Incorporate unioned sources into DAG
> *If you are running the package through [Fivetran Transformations for dbt Core™](https://fivetran.com/docs/transformations/dbt#transformationsfordbtcore), the below step is necessary in order to synchronize model runs with your Xero connections. Alternatively, you may choose to run the package through Fivetran [Quickstart](https://fivetran.com/docs/transformations/quickstart), which would create separate sets of models for each Xero source rather than one set of unioned models.*

By default, this package defines one single-connection source, called `xero`, which will be disabled if you are unioning multiple connections. This means that your DAG will not include your Xero sources, though the package will run successfully.

To properly incorporate all of your Xero connections into your project's DAG:
1. Define each of your sources in a `.yml` file in your project. Utilize the following template for the `source`-level configurations, and, **most importantly**, copy and paste the table and column-level definitions from the package's `src_xero.yml` [file](https://github.com/fivetran/dbt_xero/blob/main/models/staging/src_xero.yml).

```yml
# a .yml file in your root project

version: 2

sources:
  - name: <name> # ex: Should match name in xero_sources
    schema: <schema_name>
    database: <database_name>
    loader: fivetran
    config:
      loaded_at_field: _fivetran_synced
      freshness: # feel free to adjust to your liking
        warn_after: {count: 72, period: hour}
        error_after: {count: 168, period: hour}

    tables: # copy and paste from xero/models/staging/src_xero.yml - see https://support.atlassian.com/bitbucket-cloud/docs/yaml-anchors/ for how to use anchors to only do so once
```

2. In the above `.yml` file, remove the `and var('xero_sources', []) == []` condition from the `enabled` config for the following source tables (if you have the tables in your schemas):
- [`invoice_line_item_has_tracking_category`](https://github.com/fivetran/dbt_xero/blob/feature/new-union-data/models/staging/src_xero.yml#L191)
- [`journal_line_has_tracking_category`](https://github.com/fivetran/dbt_xero/blob/feature/new-union-data/models/staging/src_xero.yml#L206)
- [`tracking_category`](https://github.com/fivetran/dbt_xero/blob/feature/new-union-data/models/staging/src_xero.yml#L223)
- [`tracking_category_option`](https://github.com/fivetran/dbt_xero/blob/feature/new-union-data/models/staging/src_xero.yml#L243)
- [`tracking_category_has_option`](https://github.com/fivetran/dbt_xero/blob/feature/new-union-data/models/staging/src_xero.yml#L266)

3. Set the `has_defined_sources` variable (scoped to the `xero` package) to `True` in your root project, like such:
```yml
# dbt_project.yml
vars:
  xero:
    has_defined_sources: true
```

### (Optional) Additional configurations

#### Change the calendar start date
Our date-based models start at `2019-01-01` by default. To customize the start date, add the following variable to your `dbt_project.yml` file:

```yml
vars:
  xero:
    xero__calendar_start_date: 'yyyy-mm-dd' # default is 2019-01-01
```

#### Multi-currency Support Limitations
Currently, our dbt models for Xero have limited support for multi-currency accounting, particularly for handling unrealized currency gains and losses and bank revaluations, as they require historical or current exchange rate data that is not available in the Xero connector to fully calculate.

Thus, while all realized current gains will be brought through in our end models, unrealized currency gains and losses and bank revaluations will not. So we cannot provide full multi-currency support at this time.

#### Disabling and Enabling Models

When setting up your Xero connection in Fivetran, it is possible that not every table this package expects will be synced. This can occur because you either don't use that functionality in Xero or have actively decided to not sync some tables. In order to disable the relevant functionality in the package, you will need to add the relevant variables.

By default, all variables are assumed to be `true`. You only need to add variables for the tables you would like to disable:

```yml
# dbt_project.yml

config-version: 2

vars:
    xero__using_credit_note: false                      # default is true
    xero__using_bank_transaction: false                 # default is true
    xero__using_invoice_line_item_tracking_category: false  # default is true
    xero__using_journal_line_tracking_category: false # default is true
    xero__using_tracking_categories: false                # default is true
```

#### Changing the Build Schema
By default this package will build the Xero staging models within a schema titled (<target_schema> + `_stg_xero`) and the Xero final transform models within a schema titled (<target_schema> + `_xero`) in your target database.
To overwrite this behavior, add the following configuration to your `dbt_project.yml` file:

```yml
# dbt_project.yml

...
models:
    xero:
      +schema: my_new_schema_name # Leave +schema: blank to use the default target_schema.
      staging:
        +schema: my_new_schema_name # Leave +schema: blank to use the default target_schema.
#### Change the source table references
```

If an individual source table has a different name than the package expects, add the table name as it appears in your destination to the respective variable:

> IMPORTANT: See this project's [`dbt_project.yml`](https://github.com/fivetran/dbt_xero/blob/main/dbt_project.yml) variable declarations to see the expected names.

```yml
vars:
    xero_<default_source_table_name>_identifier: your_table_name 
```

### (Optional) Orchestrate your models with Fivetran Transformations for dbt Core™
<details><summary>Expand for details</summary>
<br>

Fivetran offers the ability for you to orchestrate your dbt project through [Fivetran Transformations for dbt Core™](https://fivetran.com/docs/transformations/dbt#transformationsfordbtcore). Learn how to set up your project for orchestration through Fivetran in our [Transformations for dbt Core setup guides](https://fivetran.com/docs/transformations/dbt/setup-guide#transformationsfordbtcoresetupguide).

</details>

## Does this package have dependencies?
This dbt package is dependent on the following dbt packages. These dependencies are installed by default within this package. For more information on the following packages, refer to the [dbt hub](https://hub.getdbt.com/) site.
> IMPORTANT: If you have any of these dependent packages in your own `packages.yml` file, we highly recommend that you remove them from your root `packages.yml` to avoid package version conflicts.

```yml
packages:
    - package: fivetran/fivetran_utils
      version: [">=0.4.0", "<0.5.0"]

    - package: dbt-labs/dbt_utils
      version: [">=1.0.0", "<2.0.0"]
```

<!--section="xero_maintenance"-->
## How is this package maintained and can I contribute?

### Package Maintenance
The Fivetran team maintaining this package only maintains the [latest version](https://hub.getdbt.com/fivetran/xero/latest/) of the package. We highly recommend you stay consistent with the latest version of the package and refer to the [CHANGELOG](https://github.com/fivetran/dbt_xero/blob/main/CHANGELOG.md) and release notes for more information on changes across versions.

### Contributions
A small team of analytics engineers at Fivetran develops these dbt packages. However, the packages are made better by community contributions.

We highly encourage and welcome contributions to this package. Learn how to contribute to a package in dbt's [Contributing to an external dbt package article](https://discourse.getdbt.com/t/contributing-to-a-dbt-package/657).

<!--section-end-->

## Are there any resources available?
- If you have questions or want to reach out for help, see the [GitHub Issue](https://github.com/fivetran/dbt_xero/issues/new/choose) section to find the right avenue of support for you.
- If you would like to provide feedback to the dbt package team at Fivetran or would like to request a new dbt package, fill out our [Feedback Form](https://www.surveymonkey.com/r/DQ7K7WW).
