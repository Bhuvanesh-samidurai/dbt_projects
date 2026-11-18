{#
    Points staging models at the right BRONZE table for the current target:
      * snowflake -> source('bronze', <table>)   (real tables loaded by Databricks)
      * local     -> ref(<table>)                (sample seed, so dbt builds it first)
#}
{% macro bronze_source(table_name) -%}
    {%- if target.type == 'snowflake' -%}
        {{ source('bronze', table_name) }}
    {%- else -%}
        {{ ref(table_name) }}
    {%- endif -%}
{%- endmacro %}
