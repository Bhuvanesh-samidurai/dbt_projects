{#
    Fails when the given columns together do not uniquely identify a row.
    Usage (model level):
      data_tests:
        - unique_combination:
            arguments:
              columns: [meter_id, reading_timestamp]
#}
{% test unique_combination(model, columns) %}

select
    {{ columns | join(', ') }},
    count(*) as row_count
from {{ model }}
group by {{ columns | join(', ') }}
having count(*) > 1

{% endtest %}
