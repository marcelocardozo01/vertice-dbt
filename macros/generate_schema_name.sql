{#
  Usa o nome do schema configurado no modelo (staging, intermediate, marts)
  em vez do padrão do dbt, que seria main_staging, main_marts...
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
