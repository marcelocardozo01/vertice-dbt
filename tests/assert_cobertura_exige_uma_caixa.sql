-- Toda linha de cobertura precisa ter pelo menos 1 caixa no mês
-- e a data de cobertura dentro do próprio mês.
select *
from {{ ref('fct_cobertura_produto') }}
where round(qtd_vda, 6) < 1
   or date_trunc('month', data_cobertura) <> mes_dt
