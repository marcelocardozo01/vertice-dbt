-- Itens de pedido com cliente, produto e vendedor da carteira já resolvidos.
-- Ainda SEM o filtro de venda efetiva: serve tanto para fct_pedidos (que filtra)
-- quanto para fct_pedido_status (que precisa ver cancelados e reprogramados).
with pedidos as (

    select * from {{ ref('stg_pedidos') }}

),

clientes as (

    select * from {{ ref('stg_clientes') }}

),

produtos as (

    select * from {{ ref('int_produto_classificado') }}

)

select
    p.numero_pedido,
    p.numero_romaneio,
    p.ocorrencia,
    p.codigo_cliente,
    c.codigo_cliente_fmt,
    c.codigo_vendedor_carteira,
    p.codigo_vendedor_digitacao,
    p.codigo_produto_alternativo,
    pr.codigo_produto,
    pr.descricao_produto,
    pr.categoria,
    pr.marca,
    pr.codigo_grupo,
    pr.flag_revenda,
    pr.qtd_embalagem,
    pr.fator_litros,
    p.data_lancamento,
    p.data_emissao,
    p.data_acerto,
    strftime(p.data_emissao, '%Y-%m')                               as mes,
    p.status,
    p.situacao_venda,
    p.codigo_motivo_devolucao,
    p.qtd_caixas,
    p.qtd_avulso,
    {{ caixas_equivalentes('p.qtd_caixas', 'p.qtd_avulso', 'pr.qtd_embalagem') }} as qtd_caixas_equiv,
    {{ caixas_equivalentes('p.qtd_caixas', 'p.qtd_avulso', 'pr.qtd_embalagem') }} * pr.fator_litros as litros,
    p.vl_unit,
    p.vl_total
from pedidos as p
left join clientes as c
    on c.codigo_cliente = p.codigo_cliente
left join produtos as pr
    on pr.codigo_alternativo = p.codigo_produto_alternativo
