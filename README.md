# Xero

This package models Xero data from [Fivetran's connector](https://fivetran.com/docs/applications/xero). It uses data in the format described by [this ERD](https://docs.google.com/presentation/d/1eJ5eLTWyG2ozdZYLf4oy887anCvLtoE8RhJ1VLmFrbI/edit?usp=sharing).

The package’s primary focus is to transform the core tables into analytics-ready models, including a profit and loss report, general ledger, and balance sheet report.

## Models

This package contains transformation models, designed to work simultaneously with our [Xero source package](https://github.com/fivetran/xero_source). A dependency on the source package is declared in this package's `packages.yml` file, so it will automatically download when you run `dbt deps`. The primary outputs of this package are described below.

| **model**                     | **description**                                                                                                        |
| ----------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| xero__general_ledger          | Each record represents a journal line item. Use the ledger to create the balance sheet and the profit and loss statement. |
| xero__profit_and_loss_report  | Each record represents a profit and loss line item at the month and account level.                                     |
| xero__balance_sheet_report    | Each record represents the state of the balance sheet for a given account on a given month.                            |
| xero__invoice_line_items      | Each record represents an invoice line item enriched with the account, contact, and invoice information.                   |

## Installation Instructions

Check [dbt Hub](https://hub.getdbt.com/) for the latest installation instructions, or [read the dbt docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.

## Configuration

By default, this package will look for your Xero data in the `xero` schema of your [target database](https://docs.getdbt.com/docs/running-a-dbt-project/using-the-command-line-interface/configure-your-profile). If this is not where your Xero data is,add the following configuration to your `dbt_project.yml` file:

```yml
# dbt_project.yml

...
config-version: 2

vars:
    xero_schema: your_schema_name
    xero_database: your_database_name 
```

For additional configurations for the source models, visit the [Xero source package](https://github.com/fivetran/xero_source).

## Contributions

Additional contributions to this package are very welcome! Please create issues or open PRs against `master`. See the [Discourse post](https://discourse.getdbt.com/t/contributing-to-a-dbt-package/657) on the best workflow for contributing to a package.

## Resources:
- Provide [feedback](https://www.surveymonkey.com/r/DQ7K7WW) on our existing dbt packages or what you'd like to see next
- Find all of Fivetran's pre-built dbt packages in our [dbt hub](https://hub.getdbt.com/fivetran/)
- Learn more about Fivetran [in our docs](https://fivetran.com/docs)
- Check out [Fivetran's blog](https://fivetran.com/blog)
- Learn more about dbt [in the dbt docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](http://slack.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the dbt blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices
