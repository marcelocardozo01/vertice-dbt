select
    trim(mes)                       as mes,
    trim(revenda)                   as revenda,
    trim(nivel)                     as nivel,
    trim(id)                        as codigo,
    trim(nome)                      as nome,
    cast(pdvs_ativos as integer)    as pdvs_ativos,
    trim(indicador)                 as indicador_planilha,
    cast(meta as double)            as meta,
    cast(real_planilha as double)   as real_planilha,
    arquivo
from {{ source('erp', 'metas_cobertura_planilha') }}
