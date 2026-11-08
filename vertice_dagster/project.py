"""Localização do projeto dbt e caminhos usados pelos ativos."""

import os
import sys
from pathlib import Path

from dagster_dbt import DbtCliResource, DbtProject

# O dagster-dbt chama o executável `dbt` pelo PATH. Garante que o `dbt` do mesmo
# ambiente virtual deste interpretador seja encontrado, mesmo quando o servidor de
# código do Dagster é iniciado sem o ambiente ativado.
_SCRIPTS = Path(sys.executable).parent
if str(_SCRIPTS) not in os.environ.get("PATH", ""):
    os.environ["PATH"] = str(_SCRIPTS) + os.pathsep + os.environ.get("PATH", "")

RAIZ = Path(__file__).resolve().parents[1]
DATA = RAIZ / "data"
WAREHOUSE = DATA / "warehouse" / "vertice.duckdb"
EXPORTS = DATA / "exports"

# O projeto dbt é a própria raiz do repositório; profiles.yml também fica lá.
# install_deps=False: `dbt deps` é rodado uma vez pelo desenvolvedor (ou pela CI);
# reinstalar os pacotes a cada recarga do código é lento e, em pastas sincronizadas
# (OneDrive), esbarra em bloqueio de arquivos.
dbt_project = DbtProject(
    project_dir=RAIZ,
    profiles_dir=RAIZ,
    target="dev",
    install_deps=False,
)

# Em `dagster dev` o manifest é regerado (dbt parse) a cada carga do código.
dbt_project.prepare_if_dev()

# Fora do modo dev (CLI, CI) garante que o manifest exista antes de montar os ativos.
if not dbt_project.manifest_path.exists():
    DbtCliResource(project_dir=dbt_project).cli(["parse"]).wait()
