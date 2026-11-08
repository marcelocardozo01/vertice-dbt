-- Dimensão vendedor. Nomes e hierarquia vêm da planilha do comercial, sempre do
-- mês atual; se o mês atual ainda não estiver na planilha, usa o último mês.
-- Inclui todo código que aparece nos pedidos (quem digitou) ou na carteira dos
-- clientes (dono do cliente). Rótulos prontos para filtro: "511 - ALICE SOUTO".
with hierarquia as (

    select * from {{ ref('stg_hierarquia_vendas') }}

),

mes_ref as (

    select coalesce(
        max(mes) filter (where mes <= strftime(current_date, '%Y-%m')),
        max(mes)
    ) as mes
    from hierarquia

),

h as (

    select hv.*
    from hierarquia as hv
    inner join mes_ref as m
        on m.mes = hv.mes

),

codigos as (

    select distinct codigo_vendedor_digitacao as codigo_vendedor from {{ ref('stg_pedidos') }}
    union
    select distinct codigo_vendedor_carteira from {{ ref('stg_clientes') }}
    union
    select distinct codigo_vendedor from h

)

select
    c.codigo_vendedor,
    h.nome_vendedor,
    c.codigo_vendedor || coalesce(' - ' || h.nome_vendedor, '')     as vendedor,
    h.codigo_supervisor || ' - ' || h.nome_supervisor               as supervisor,
    h.codigo_gerente || ' - ' || h.nome_gerente                     as gerente_vendas,
    h.revenda,
    (select mes from mes_ref)                                       as mes_hierarquia
from codigos as c
left join h
    on h.codigo_vendedor = c.codigo_vendedor
where coalesce(c.codigo_vendedor, '') <> ''
order by c.codigo_vendedor
