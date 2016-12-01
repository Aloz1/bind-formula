{% from "bind/map.jinja" import map with context %}

bind_running:
  service.running:
    - name: {{ map.service.name }}
    - enable: True
    - reload: True
    - require:
      - pkg: bind_install

#bind_restart:
#  service.running:
#    - name: {{## map.service.name ##}}
#    - reload: False
#    - watch:
#      - file: {{## map.dirs.log ##}}/query.log
