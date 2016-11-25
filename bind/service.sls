{% from "bind/map.jinja" import map with context %}

bind_running:
  service.running:
    - name: {{ map.service }}
    - enable: True
    - reload: True
    - require:
        - pkg: bind_install
        - pkg: bind_config

bind_restart:
  service.running:
    - name: {{ map.service }}
    - reload: False
    - watch:
      - file: {{ map.log_dir }}/query.log
