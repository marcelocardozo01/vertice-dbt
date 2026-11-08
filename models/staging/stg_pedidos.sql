-- Staging de pedidos: só renomeia, tipa e limpa. Nenhuma regra de negócio aqui.
with src as (

    select * from {{ source('erp', 'pedidos') }}

)

select
    cast(numero_pedido as bigint)                                   as numero_pedido,
    cast(numero_romaneio as bigint)                                 as numero_romaneio,
    cast(ocorrencia as integer)                                     as ocorrencia,
    cast(codigo_cliente as bigint)                                  as codigo_cliente,
    trim(codigo_vendedor)                                           as codigo_vendedor_digitacao,
    cast(codigo_produto_alternativo as bigint)                      as codigo_produto_alternativo,
    {{ yyyymmdd_to_date('data_lancamento') }}                       as data_lancamento,
    {{ yyyymmdd_to_date('data_emissao') }}                          as data_emissao,
    {{ yyyymmdd_to_date('data_acerto') }}                           as data_acerto,
    trim(status)                                                    as status,
    trim(situacao_venda)                                            as situacao_venda,
    nullif(trim(coalesce(codigo_motivo_devolucao, '')), '')         as codigo_motivo_devolucao,
    cast(quantidade_saida as bigint)                                as qtd_caixas,
    cast(quantidade_saida_avulso as bigint)                         as qtd_avulso,
    cast(vl_unit as double)                                         as vl_unit,
    cast(vl_total as double)                                        as vl_total,
    trim(usuario_criacao)                                           as usuario_criacao,
    trim(tab_ref)                                                   as tab_ref
from src
