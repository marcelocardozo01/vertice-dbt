-- Classificação de produtos: um lugar só para as regras que dizem a que grupo
-- cada SKU pertence. Todas as coberturas e indicadores leem daqui.
--
--   flag_revenda     : produto de revenda (grupo 1); acessório (borrifador, balde) fica de fora
--   marca_principal  : LIMPORA, BRILHAX, NUVELLA, ZESTRA
--   marca_eco        : linha ecológica (VERDANTA, ECOLIM, BROTA, MARE)
--   marca_especial   : LIMPORA ZERO (sem perfume) e higiene (SUAVITTA, FRESCOR)
--   marca            : a primeira das três que existir; 'OUTRAS' se nenhuma
--   flag_refil       : categoria REFIL 1L ou REFIL 2L
--   flag_galao       : categoria GALAO 5L
--   flag_refil_2l    : categoria REFIL 2L
--   flag_concentrado : "CONCENTRADO" na descrição
--
-- Grão: 1 linha por produto (codigo_alternativo).
with produtos as (

    select * from {{ ref('stg_produtos') }}

),

categorias as (

    select * from {{ ref('stg_categorias') }}

),

base as (

    select
        p.codigo_alternativo,
        p.codigo_produto,
        p.codigo_produto_txt,
        upper(p.descricao_produto)      as descricao_produto,
        c.categoria,
        p.codigo_grupo,
        p.qtd_embalagem,
        p.fator_litros,
        p.linha,
        p.codigo_grupo = '1'            as flag_revenda
    from produtos as p
    left join categorias as c
        on c.codigo_categoria = p.codigo_categoria

),

classificado as (

    select
        *,
        case
            when not flag_revenda then null
            when descricao_produto like 'LIMPORA%' then 'LIMPORA'
            when descricao_produto like 'BRILHAX%' then 'BRILHAX'
            when descricao_produto like 'NUVELLA%' then 'NUVELLA'
            when descricao_produto like 'ZESTRA%' then 'ZESTRA'
        end                                                     as marca_principal,
        case
            when not flag_revenda then null
            when descricao_produto like 'VERDANTA%' then 'VERDANTA'
            when descricao_produto like 'ECOLIM%' then 'ECOLIM'
            when descricao_produto like 'BROTA%' then 'BROTA'
            when descricao_produto like 'MARE%' then 'MARE'
        end                                                     as marca_eco,
        case
            when not flag_revenda then null
            when descricao_produto like 'LIMPORA ZERO%' then 'LIMPORA ZERO'
            when descricao_produto like 'SUAVITTA%' then 'SUAVITTA'
            when descricao_produto like 'FRESCOR%' then 'FRESCOR'
        end                                                     as marca_especial,
        coalesce(categoria like 'REFIL%', false)                as flag_refil,
        coalesce(categoria like 'GALAO%', false)                as flag_galao,
        coalesce(categoria = 'REFIL 2L', false)                 as flag_refil_2l,
        descricao_produto like '%CONCENTRADO%'                  as flag_concentrado
    from base

)

select
    *,
    coalesce(marca_principal, marca_eco, marca_especial, 'OUTRAS') as marca
from classificado
