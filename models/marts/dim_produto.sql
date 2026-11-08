-- Dimensão produto: 1 linha por SKU, com a mesma classificação usada nas coberturas.
select
    codigo_alternativo,
    codigo_produto,
    codigo_produto_txt,
    descricao_produto,
    categoria,
    marca,
    marca_principal,
    marca_eco,
    marca_especial,
    linha,
    codigo_grupo,
    flag_revenda,
    flag_refil,
    flag_galao,
    flag_refil_2l,
    flag_concentrado,
    qtd_embalagem,
    fator_litros
from {{ ref('int_produto_classificado') }}
order by codigo_alternativo
