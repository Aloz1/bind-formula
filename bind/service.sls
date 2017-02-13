{% from "bind/map.jinja" import map with context %}

bind_running:
  service.running:
    - name: {{ map.service_name }}
    - enable: true
    - reload: true
    - require:
      - pkg: bind_install
