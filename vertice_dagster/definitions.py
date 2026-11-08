"""Ponto de entrada do Dagster: `dagster dev` lê este módulo via [tool.dagster] no pyproject."""

from dagster import (
    AssetSelection,
    DefaultScheduleStatus,
    Definitions,
    ScheduleDefinition,
    define_asset_job,
)
from dagster_dbt import DbtCliResource

from vertice_dagster.assets import exports_power_bi, planilhas_comerciais, vertice_dbt_assets
from vertice_dagster.project import dbt_project

# Um job com o ELT inteiro: planilhas -> dbt build -> exports.
elt_vertice = define_asset_job(
    name="elt_vertice",
    selection=AssetSelection.all(),
    description="Extração das planilhas, dbt build (modelos + testes) e exportação para o Power BI.",
)

# Dias úteis às 06:00 (horário de Brasília). Começa desligado; ligue na UI ou por `dagster schedule start`.
elt_diario = ScheduleDefinition(
    name="elt_diario",
    job=elt_vertice,
    cron_schedule="0 6 * * 1-5",
    execution_timezone="America/Sao_Paulo",
    default_status=DefaultScheduleStatus.STOPPED,
)

defs = Definitions(
    assets=[planilhas_comerciais, vertice_dbt_assets, exports_power_bi],
    jobs=[elt_vertice],
    schedules=[elt_diario],
    resources={"dbt": DbtCliResource(project_dir=dbt_project)},
)
