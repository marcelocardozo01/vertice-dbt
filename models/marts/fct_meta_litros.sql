-- Metas de volume em litros. O ERP traz a meta em CAIXAS por vendedor e produto;
-- meta_litros = meta_caixas x fator de litros do produto (mesmo fator de fct_pedidos).
-- Só meses a partir do primeiro mês com pedidos (antes não há realizado para comparar).
-- Grão: 1 linha por mês x vendedor x produto.
with metas as (

    select * from {{ ref('stg_metas_volume') }}

),

produtos as (

    select * from {{ ref('dim_produto') }}

),

inicio as (

    select min(mes) as mes from {{ ref('fct_pedidos') }}

)

select
    m.mes_ref,
    m.mes_dt,
    m.codigo_vendedor,
    m.codigo_produto_alternativo,
    p.fator_litros,
    m.meta_caixas,
    m.meta_caixas * p.fator_litros      as meta_litros
from metas as m
cross join inicio as i
left join produtos as p
    on p.codigo_alternativo = m.codigo_produto_alternativo
where m.mes_ref >= i.mes
