with src as (

    select * from {{ source('erp', 'produtos') }}

),

linha as (

    select * from {{ source('erp', 'produtos_linha') }}

)

select
    cast(p.codigo_alternativo as bigint)        as codigo_alternativo,
    cast(p.codigo_produto as bigint)            as codigo_produto,
    cast(cast(p.codigo_produto as bigint) as varchar) as codigo_produto_txt,
    trim(p.descricao_produto)                   as descricao_produto,
    trim(p.codigo_grupo)                        as codigo_grupo,
    cast(p.codigo_categoria as varchar)         as codigo_categoria,
    cast(p.quantidade_embalagem as bigint)      as qtd_embalagem,
    cast(p.fator_litros as double)              as fator_litros,
    trim(l.linha)                               as linha
from src as p
left join linha as l
    on l.codigo_alternativo = p.codigo_alternativo
