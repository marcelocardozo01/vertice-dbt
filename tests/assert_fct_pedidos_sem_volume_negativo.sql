-- Nenhum item de venda efetiva pode ter litros ou caixas negativos.
-- Se retornar linhas, o teste falha.
select *
from {{ ref('fct_pedidos') }}
where litros < 0
   or qtd_caixas_equiv < 0
