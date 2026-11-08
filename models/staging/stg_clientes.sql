with src as (

    select * from {{ source('erp', 'clientes') }}

)

select
    cast(codigo_cliente as bigint)      as codigo_cliente,
    {{ fmt_codigo_cliente('codigo_cliente') }} as codigo_cliente_fmt,
    trim(codigo_vendedor)               as codigo_vendedor_carteira,
    trim(codigo_canal)                  as codigo_canal,
    trim(cidade)                        as cidade,
    trim(situacao)                      as situacao,
    cast(codigo_pasta as bigint)        as codigo_pasta,
    trim(fantasia)                      as fantasia,
    trim(razao_social)                  as razao_social
from src
