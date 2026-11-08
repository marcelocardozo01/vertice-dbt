select
    trim(codigo)            as codigo_categoria,
    upper(trim(descricao))  as categoria
from {{ source('erp', 'categorias') }}
