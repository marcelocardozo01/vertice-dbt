-- Destino dos pedidos (perdas operacionais). 1 linha por pedido (capa), só revenda.
--
--   tipo : Efetivo      acertado sem motivo de devolução
--          Em aberto    ainda não acertado
--          Devolvido    acertado com motivo de devolução
--          Reprogramado status REPROGRAMADO
--          Cancelado    status CANCELADO
--   litros : volume de venda do pedido (ocorrência 1)
--
--   voltou_15d : para pedido não efetivado, o cliente teve pedido efetivo (ou em
--                aberto) em até 15 dias depois. Só vale quando avaliavel (pedido
--                com 15 dias ou mais em relação à data de referência).
with ped as (

    select
        numero_pedido,
        codigo_cliente,
        codigo_vendedor_carteira                                    as codigo_vendedor,
        data_emissao                                                as dt,
        max(status)                                                 as status,
        max(coalesce(codigo_motivo_devolucao, ''))                  as motivo,
        coalesce(sum(litros) filter (where ocorrencia = 1), 0)      as litros
    from {{ ref('int_pedidos_enriquecidos') }}
    where flag_revenda
    group by 1, 2, 3, 4

),

tipado as (

    select
        *,
        case
            when status = 'CANCELADO' then 'Cancelado'
            when status = 'REPROGRAMADO' then 'Reprogramado'
            when status = 'ACERTADO' and motivo <> '' then 'Devolvido'
            when status = 'ACERTADO' then 'Efetivo'
            else 'Em aberto'
        end as tipo
    from ped

),

ref_dt as (

    select max(dt) as dt_ref from ped

),

motivos as (

    select * from {{ ref('stg_motivos_devolucao') }}

)

select
    t.numero_pedido,
    t.codigo_cliente,
    t.codigo_vendedor,
    t.dt,
    strftime(t.dt, '%Y-%m')                                         as mes,
    t.status,
    t.tipo,
    case t.tipo
        when 'Efetivo' then 1 when 'Em aberto' then 2 when 'Devolvido' then 3
        when 'Reprogramado' then 4 else 5
    end                                                             as ordem_tipo,
    nullif(t.motivo, '')                                            as motivo,
    case when t.motivo <> '' then coalesce(m.motivo_devolucao, t.motivo) end as motivo_desc,
    t.litros,
    t.dt <= r.dt_ref - 15                                           as avaliavel,
    case
        when t.tipo in ('Efetivo', 'Em aberto') then null
        else exists (
            select 1
            from tipado as e
            where e.codigo_cliente = t.codigo_cliente
              and e.dt > t.dt
              and e.dt <= t.dt + 15
              and e.tipo in ('Efetivo', 'Em aberto')
        )
    end                                                             as voltou_15d
from tipado as t
cross join ref_dt as r
left join motivos as m
    on m.codigo_motivo_devolucao = t.motivo
