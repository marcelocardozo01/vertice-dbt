"""Etapa E do ELT: deixa tudo em Parquet dentro de data/raw.

Na empresa real esta etapa seria a extração do ERP (ODBC -> Parquet). Aqui os
Parquet do ERP já estão em data/raw (base fictícia da Vértice Distribuidora), e
este script converte o que chega em Excel do time comercial:

  data/source_xlsx/hierarquia_vendas.xlsx            -> data/raw/hierarquia_vendas.parquet
  data/source_xlsx/metas_cobertura/Metas Cobertura_*.xlsx -> data/raw/metas_cobertura_planilha.parquet

A planilha de metas de cobertura é lida pelos NOMES das colunas da aba RESUMO,
nunca pela posição, porque o layout muda de mês para mês.

Uso: uv run python scripts/extract.py
"""

import re
from pathlib import Path

import openpyxl
import pandas as pd

RAIZ = Path(__file__).resolve().parents[1]
XLSX = RAIZ / "data" / "source_xlsx"
RAW = RAIZ / "data" / "raw"


def ler_resumo(arquivo: Path, mes: str) -> list[dict]:
    """Lê a aba RESUMO de uma planilha de metas de cobertura.

    linha do topo : nome do indicador (bloco Meta | Real | Neces. /dia | % M/R)
    cabeçalho     : Revenda, NÍVEL, CodGV, CodSV, Id, Nome, PDVs Ativos, Meta, Real...
    """
    wb = openpyxl.load_workbook(arquivo, read_only=True, data_only=True)
    try:
        linhas = list(wb["RESUMO"].iter_rows(values_only=True))
    finally:
        wb.close()
    h = next(i for i, r in enumerate(linhas[:15]) if r and "Id" in [str(x).strip() for x in r if x is not None])
    cab = [str(x).strip() if x is not None else "" for x in linhas[h]]
    topo = linhas[h - 1]
    col = {n: cab.index(n) for n in ["Revenda", "NÍVEL", "CodGV", "CodSV", "Id", "Nome", "PDVs Ativos"]}
    blocos, vistos = [], {}
    for j, x in enumerate(topo):
        if x is None or not str(x).strip() or cab[j] != "Meta":
            continue
        nome = str(x).strip()
        vistos[nome] = vistos.get(nome, 0) + 1
        if vistos[nome] > 1:
            nome = f"{nome} #{vistos[nome]}"
        blocos.append((nome, j, j + 1))
    out = []
    for r in linhas[h + 1 :]:
        if not r or r[col["NÍVEL"]] not in ("GC", "GV", "SV", "VD"):
            continue
        for nome, jm, jr in blocos:
            meta = r[jm] if isinstance(r[jm], (int, float)) else None
            real = r[jr] if isinstance(r[jr], (int, float)) else None
            out.append(
                {
                    "MES": mes,
                    "REVENDA": r[col["Revenda"]],
                    "NIVEL": r[col["NÍVEL"]],
                    "ID": None if r[col["Id"]] is None else str(int(r[col["Id"]])),
                    "NOME": r[col["Nome"]],
                    "PDVS_ATIVOS": r[col["PDVs Ativos"]],
                    "INDICADOR": nome,
                    "META": meta,
                    "REAL_PLANILHA": real,
                    "ARQUIVO": arquivo.name,
                }
            )
    return out


def main() -> None:
    RAW.mkdir(parents=True, exist_ok=True)

    hier = pd.read_excel(XLSX / "hierarquia_vendas.xlsx", sheet_name="HIERARQUIA", dtype=str)
    hier = hier.apply(lambda c: c.str.strip())
    hier.to_parquet(RAW / "hierarquia_vendas.parquet", index=False)
    print(f"hierarquia_vendas.parquet: {len(hier):,} linhas")

    linhas: list[dict] = []
    for f in sorted((XLSX / "metas_cobertura").glob("Metas Cobertura_*.xlsx")):
        m = re.search(r"_(\d{4}-\d{2})", f.name)
        if m:
            linhas += ler_resumo(f, m.group(1))
    metas = pd.DataFrame(linhas)
    metas.to_parquet(RAW / "metas_cobertura_planilha.parquet", index=False)
    print(f"metas_cobertura_planilha.parquet: {len(metas):,} linhas")


if __name__ == "__main__":
    main()
