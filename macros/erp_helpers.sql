{#
  Datas do ERP chegam como inteiro AAAAMMDD (0 = sem data).
#}
{% macro yyyymmdd_to_date(coluna) -%}
    cast(try_strptime(cast(nullif({{ coluna }}, 0) as varchar), '%Y%m%d') as date)
{%- endmacro %}

{#
  Código do cliente no padrão de exibição 0000-0000.
#}
{% macro fmt_codigo_cliente(coluna) -%}
    concat(
        substr(lpad(cast({{ coluna }} as varchar), 8, '0'), 1, 4), '-',
        substr(lpad(cast({{ coluna }} as varchar), 8, '0'), 5, 4)
    )
{%- endmacro %}

{#
  Caixas equivalentes: caixas fechadas + avulsos convertidos pela embalagem.
#}
{% macro caixas_equivalentes(qtd_caixas, qtd_avulso, qtd_embalagem) -%}
    ({{ qtd_caixas }} + coalesce({{ qtd_avulso }} / nullif({{ qtd_embalagem }}, 0), 0))
{%- endmacro %}
