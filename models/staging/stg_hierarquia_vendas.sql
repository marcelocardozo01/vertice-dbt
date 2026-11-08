select
    trim(mes)       as mes,
    trim(gv)        as codigo_gerente,
    trim(nome_gv)   as nome_gerente,
    trim(revenda)   as revenda,
    trim(sv)        as codigo_supervisor,
    trim(nome_sv)   as nome_supervisor,
    trim(vd)        as codigo_vendedor,
    trim(nome_vd)   as nome_vendedor
from {{ source('erp', 'hierarquia_vendas') }}
