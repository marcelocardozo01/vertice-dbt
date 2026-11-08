select
    printf('%04d-%02d', ano_referencia, mes_referencia)             as mes_ref,
    cast(make_date(ano_referencia, mes_referencia, 1) as date)      as mes_dt,
    trim(codigo_vendedor)                                           as codigo_vendedor,
    cast(codigo_produto_alternativo as bigint)                      as codigo_produto_alternativo,
    cast(meta_volume as bigint)                                     as meta_caixas
from {{ source('erp', 'metas_volume') }}
