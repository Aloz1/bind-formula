{% from "bind/map.jinja" import map with context %}

bind_running:
  service.running:
    - name: {{ map.service.name }}
    - enable: True
    - reload: True
    - require:
        - pkg: bind_install
        - pkg: bind_config

bind_restart:
  service.running:
    - name: {{ map.service.name }}
    - reload: False
    - watch:
      - file: {{ map.dir.log }}/query.log
