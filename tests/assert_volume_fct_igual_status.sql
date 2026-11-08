-- Reconciliação entre marts: o volume de venda (ocorrência 1) dos pedidos
-- efetivos em fct_pedidos tem de bater com os litros dos pedidos do tipo
-- Efetivo + Em aberto em fct_pedido_status, dentro de 0,01 litro.
with por_pedidos as (

    select sum(litros) as litros
    from {{ ref('fct_pedidos') }}
    where ocorrencia = 1
      and codigo_motivo_devolucao is null

),

por_status as (

    select sum(litros) as litros
    from {{ ref('fct_pedido_status') }}
    where tipo in ('Efetivo', 'Em aberto')

)

select p.litros as litros_fct_pedidos, s.litros as litros_fct_status
from por_pedidos as p
cross join por_status as s
where abs(p.litros - s.litros) > 0.01
