-- Meta x realizado de volume por mês, vendedor e produto, em litros.
-- Realizado = venda efetiva (ocorrência 1); bonificação fica em coluna separada.
-- Grão: 1 linha por mês x vendedor x produto com meta ou realizado.
with realizado as (

    select
        mes,
        codigo_vendedor_carteira                                    as codigo_vendedor,
        codigo_produto_alternativo,
        sum(litros) filter (where ocorrencia = 1)                   as litros_venda,
        sum(litros) filter (where ocorrencia = 2)                   as litros_bonificacao,
        count(distinct codigo_cliente)                              as clientes_atendidos
    from {{ ref('fct_pedidos') }}
    group by 1, 2, 3

),

meta as (

    select
        mes_ref                                                     as mes,
        codigo_vendedor,
        codigo_produto_alternativo,
        meta_caixas,
        meta_litros
    from {{ ref('fct_meta_litros') }}

),

chaves as (

    select mes, codigo_vendedor, codigo_produto_alternativo from realizado
    union
    select mes, codigo_vendedor, codigo_produto_alternativo from meta

)

select
    k.mes,
    k.codigo_vendedor,
    k.codigo_produto_alternativo,
    p.descricao_produto,
    p.marca,
    coalesce(m.meta_caixas, 0)                                      as meta_caixas,
    coalesce(m.meta_litros, 0)                                      as meta_litros,
    coalesce(r.litros_venda, 0)                                     as litros_venda,
    coalesce(r.litros_bonificacao, 0)                               as litros_bonificacao,
    coalesce(r.clientes_atendidos, 0)                               as clientes_atendidos,
    case when coalesce(m.meta_litros, 0) > 0
         then coalesce(r.litros_venda, 0) / m.meta_litros end       as atingimento
from chaves as k
left join realizado as r
    on r.mes = k.mes and r.codigo_vendedor = k.codigo_vendedor
   and r.codigo_produto_alternativo = k.codigo_produto_alternativo
left join meta as m
    on m.mes = k.mes and m.codigo_vendedor = k.codigo_vendedor
   and m.codigo_produto_alternativo = k.codigo_produto_alternativo
left join {{ ref('dim_produto') }} as p
    on p.codigo_alternativo = k.codigo_produto_alternativo
