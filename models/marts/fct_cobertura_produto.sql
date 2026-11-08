-- Cobertura por produto: cliente coberto em um SKU no mês = comprou pelo menos
-- 1 caixa do SKU no mês, somando os pedidos. data_cobertura é o dia em que o
-- acumulado do mês chegou a 1 caixa.
--
-- Grão: 1 linha por mês x produto x vendedor da carteira x cliente.
with itens as (

    select * from {{ ref('int_cobertura_itens') }}

),

vendedores as (

    select * from {{ ref('dim_vendedor') }}

)

select
    i.mes_dt,
    strftime(i.mes_dt, '%Y-%m')                                     as mes,
    i.codigo_produto,
    any_value(i.codigo_produto_alternativo)                         as codigo_produto_alternativo,
    i.codigo_cliente,
    i.codigo_vendedor_carteira,
    any_value(v.supervisor)                                         as supervisor,
    any_value(v.gerente_vendas)                                     as gerente_vendas,
    any_value(v.revenda)                                            as revenda,
    sum(i.qtd_vda)                                                  as qtd_vda,
    min(i.data_emissao) filter (where round(i.qtd_acumulada, 6) >= 1) as data_cobertura
from itens as i
left join vendedores as v
    on v.codigo_vendedor = i.codigo_vendedor_carteira
group by i.mes_dt, i.codigo_produto, i.codigo_cliente, i.codigo_vendedor_carteira
having round(sum(i.qtd_vda), 6) >= 1
