"""Orquestração do ELT da Vértice Distribuidora com Dagster.

Ativos (assets):
  erp/hierarquia_vendas, erp/metas_cobertura_planilha  -> planilhas Excel convertidas em Parquet
  stg_*, int_*, dim_*, fct_*, agg_*                    -> modelos dbt (testes viram asset checks)
  exports_power_bi                                     -> marts exportados em Parquet para o Power BI
"""
