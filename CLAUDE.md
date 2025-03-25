# DBT Xero Package Guidelines

## Commands
- Run the package: `dbt run`
- Test all models: `dbt test`
- Run a single test: `dbt test --select path/to/test`
- Build docs: `dbt docs generate`
- Compile SQL: `dbt compile`
- Check source freshness: `dbt source freshness`

## Style Guidelines
- **SQL Formatting**: Use uppercase for SQL keywords, lowercase for identifiers
- **Model Naming**: Use snake_case with the `xero__` prefix for final models
- **Field Naming**: Use snake_case for field names
- **Documentation**: Document all models in YAML files
- **Materialization**: Explicitly declare materializations (view, table, incremental)
- **CTE Usage**: Use CTEs for readability and modularity
- **Jinja**: Minimize complex Jinja logic in SQL files
- **Tests**: Add tests for all key relations and unique/not null constraints

## Package Structure
- Base models reside in `models/` directory
- Utilities in `models/utilities/`
- Integration tests in `integration_tests/`