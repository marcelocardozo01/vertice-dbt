select
    trim(codigo)        as codigo_canal,
    trim(descricao)     as canal
from {{ source('erp', 'canais') }}
