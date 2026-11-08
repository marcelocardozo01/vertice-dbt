select
    trim(codigo)        as codigo_motivo_devolucao,
    trim(descricao)     as motivo_devolucao
from {{ source('erp', 'motivos_devolucao') }}
