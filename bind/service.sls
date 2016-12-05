{% from "bind/map.jinja" import map with context %}

bind_running:
  service.running:
    - name: {{ map.service_name }}
    - enable: True
    - reload: True
    - require:
      - pkg: bind_install
