-- Itens que contam para cobertura, com a quantidade acumulada no mês por
-- cliente x produto x vendedor. SEM o corte de 1 caixa: coberturas com outro
-- mínimo (linha eco, 6 unidades...) também partem daqui.
--
-- Regras:
--   * só produtos de revenda
--   * sem REPROGRAMADO e CANCELADO
--   * venda (1) e bonificação (2)
--   * sem motivo de devolução
with itens as (

    select
        data_emissao,
        numero_pedido,
        ocorrencia,
        codigo_cliente,
        codigo_produto_alternativo,
        codigo_produto,
        codigo_vendedor_carteira,
        qtd_caixas_equiv                        as qtd_vda,
        cast(date_trunc('month', data_emissao) as date) as mes_dt
    from {{ ref('int_pedidos_enriquecidos') }}
    where flag_revenda
      and status not in ('REPROGRAMADO', 'CANCELADO')
      and ocorrencia in (1, 2)
      and codigo_motivo_devolucao is null

)

select
    *,
    sum(qtd_vda) over (
        partition by mes_dt, codigo_produto, codigo_vendedor_carteira, codigo_cliente
        order by data_emissao, numero_pedido, ocorrencia
        rows between unbounded preceding and current row
    ) as qtd_acumulada
from itens
