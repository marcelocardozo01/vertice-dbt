"""Ativos do ELT: extração (Python) -> transformação (dbt) -> exportação (DuckDB -> Parquet)."""

import importlib.util
from collections.abc import Iterator
from typing import Any

import duckdb
from dagster import (
    AssetExecutionContext,
    AssetKey,
    AssetSpec,
    MaterializeResult,
    MetadataValue,
    asset,
    multi_asset,
)
from dagster_dbt import DagsterDbtTranslator, DbtCliResource, dbt_assets, get_asset_key_for_model

from vertice_dagster.project import EXPORTS, RAIZ, WAREHOUSE, dbt_project

# --------------------------------------------------------------------------- extração


def _extract_module():
    """Carrega scripts/extract.py sem transformar a pasta scripts em pacote."""
    caminho = RAIZ / "scripts" / "extract.py"
    spec = importlib.util.spec_from_file_location("extract", caminho)
    modulo = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(modulo)
    return modulo


PLANILHAS = {
    "hierarquia_vendas": "Hierarquia vendedor > supervisor > gerente por mês, da planilha do comercial.",
    "metas_cobertura_planilha": "Metas de cobertura por indicador, lidas da aba RESUMO das planilhas mensais.",
}


@multi_asset(
    specs=[
        AssetSpec(
            key=AssetKey(["erp", nome]),
            group_name="fontes",
            kinds={"python", "excel"},
            description=descricao,
        )
        for nome, descricao in PLANILHAS.items()
    ],
)
def planilhas_comerciais(context: AssetExecutionContext) -> Iterator[MaterializeResult]:
    """Converte as planilhas Excel do comercial em Parquet dentro de data/raw.

    As chaves destes ativos coincidem com as fontes `erp.hierarquia_vendas` e
    `erp.metas_cobertura_planilha` do dbt, por isso aparecem ligadas aos modelos
    staging no grafo de linhagem.
    """
    _extract_module().main()
    con = duckdb.connect()
    for nome in PLANILHAS:
        arquivo = RAIZ / "data" / "raw" / f"{nome}.parquet"
        linhas = con.execute(f"select count(*) from read_parquet('{arquivo.as_posix()}')").fetchone()[0]
        context.log.info("%s: %s linhas", nome, f"{linhas:,}")
        yield MaterializeResult(
            asset_key=AssetKey(["erp", nome]),
            metadata={"linhas": linhas, "arquivo": MetadataValue.path(str(arquivo))},
        )


# --------------------------------------------------------------------------- dbt


class VerticeDbtTranslator(DagsterDbtTranslator):
    """Agrupa os ativos pela camada do dbt (staging, intermediate, marts, seeds, fontes)."""

    def get_group_name(self, dbt_resource_props: dict[str, Any]) -> str | None:
        tipo = dbt_resource_props["resource_type"]
        if tipo == "source":
            return "fontes"
        if tipo == "seed":
            return "seeds"
        fqn = dbt_resource_props.get("fqn", [])
        return fqn[1] if len(fqn) > 2 else "dbt"


@dbt_assets(
    manifest=dbt_project.manifest_path,
    dagster_dbt_translator=VerticeDbtTranslator(),
)
def vertice_dbt_assets(context: AssetExecutionContext, dbt: DbtCliResource) -> Iterator:
    """Roda `dbt build` (seeds, modelos e testes). Cada teste vira um asset check."""
    yield from dbt.cli(["build"], context=context).stream()


# --------------------------------------------------------------------------- exportação

MARTS_EXPORTADOS = [
    "dim_vendedor",
    "dim_produto",
    "fct_pedidos",
    "fct_cobertura_produto",
    "fct_meta_litros",
    "fct_pedido_status",
    "agg_meta_realizado_mensal",
]


@asset(
    group_name="exportacao",
    kinds={"duckdb", "parquet"},
    deps=[get_asset_key_for_model([vertice_dbt_assets], mart) for mart in MARTS_EXPORTADOS],
    description="Marts exportados em Parquet (ZSTD) para o Power BI ler pelo parâmetro PastaExports.",
)
def exports_power_bi(context: AssetExecutionContext) -> MaterializeResult:
    EXPORTS.mkdir(parents=True, exist_ok=True)
    con = duckdb.connect(str(WAREHOUSE), read_only=True)
    linhas_por_tabela: dict[str, int] = {}
    try:
        for mart in MARTS_EXPORTADOS:
            destino = (EXPORTS / f"{mart}.parquet").as_posix()
            con.execute(f"copy marts.{mart} to '{destino}' (format parquet, compression zstd)")
            linhas_por_tabela[mart] = con.execute(f"select count(*) from marts.{mart}").fetchone()[0]
            context.log.info("%s -> %s linhas", mart, f"{linhas_por_tabela[mart]:,}")
    finally:
        con.close()
    return MaterializeResult(
        metadata={
            "tabelas": len(linhas_por_tabela),
            "linhas_total": sum(linhas_por_tabela.values()),
            "pasta": MetadataValue.path(str(EXPORTS)),
            "detalhe": MetadataValue.json(linhas_por_tabela),
        }
    )
