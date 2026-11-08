-- Fato de pedidos: base de volume e faturamento (venda efetiva).
--
-- Regras de venda efetiva:
--   * só produtos de revenda (grupo 1) com marca conhecida
--   * sem REPROGRAMADO (cópia diária até entregar) e CANCELADO
--   * ocorrência 1 (venda) e 2 (bonificação)
--   * motivo de devolução só tira o pedido depois de ACERTADO
--     (em pedido ABERTO o motivo ainda não é devolução confirmada)
--
-- Volume: litros = (caixas + avulsos / embalagem) x fator de litros.
-- Hierarquia e volume seguem o vendedor da CARTEIRA do cliente.
-- flag_provisorio: pedido ainda não acertado (pode mudar).
with pedidos as (

    select * from {{ ref('int_pedidos_enriquecidos') }}

),

vendedores as (

    select * from {{ ref('dim_vendedor') }}

),

efetivos as (

    select *
    from pedidos
    where flag_revenda
      and status not in ('REPROGRAMADO', 'CANCELADO')
      and ocorrencia in (1, 2)
      and (codigo_motivo_devolucao is null or status = 'ABERTO')
      and marca <> 'OUTRAS'

)

select
    e.numero_pedido,
    e.numero_romaneio,
    e.ocorrencia,
    case e.ocorrencia when 1 then 'Venda' else 'Bonificação' end    as tipo_ocorrencia,
    e.codigo_cliente,
    e.codigo_cliente_fmt,
    e.codigo_vendedor_carteira,
    e.codigo_vendedor_digitacao,
    v.vendedor,
    v.supervisor,
    v.gerente_vendas,
    v.revenda,
    e.codigo_produto_alternativo,
    e.codigo_produto,
    e.descricao_produto,
    e.categoria,
    e.marca,
    e.data_lancamento,
    e.data_emissao,
    e.data_acerto,
    e.mes,
    e.status,
    e.status <> 'ACERTADO'                                          as flag_provisorio,
    e.codigo_motivo_devolucao,
    e.qtd_caixas,
    e.qtd_avulso,
    e.qtd_caixas_equiv,
    e.litros,
    e.vl_unit,
    e.vl_total
from efetivos as e
left join vendedores as v
    on v.codigo_vendedor = e.codigo_vendedor_carteira
