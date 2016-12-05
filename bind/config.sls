{% from "bind/map.jinja" import map with context %}

include:
  - bind

{% for dir_name, dir_opts in map.dirs.items() %}

{{ dir_name }}:
  file.directory:
    - user: {{ dir_opts.user|default( map.user ) }}
    - group: {{ dir_opts.group|default( map.group ) }}
    - mode: {{ dir_opts.mode|default( map.modes.dir ) }}

    - makedirs: True

    - require_in:
      - bind_running

    - watch_in:
      - bind_running

{% for file_name, file_opts in (dir_opts.files|default( {} )).items() %}

{{ dir_name }}/{{ file_name }}:
  file.managed:
    - source: {{ map.template_dir|default('salt://bind/files/default') }}/{{ file_opts.source|default( file_name ) }}
    - template: {{ file_opts.template|default( 'jinja' ) }}

    - user: {{ file_opts.user|default( map.user ) }}
    - group: {{ file_opts.group|default( map.group ) }}
    - mode: {{ file_opts.mode|default( map.modes.file ) }}

    - require:
      - {{ dir_name }}

    - require_in:
      - bind_running

    - watch_in:
      - bind_running

{% endfor %}
{% endfor %}

{#
named_log_dir:
  file.directory:
    - name: {{ map.dirs.log }}:
    - user: root
    - group: {{ salt['pillar.get']('bind:config:group', map.group) }}
    - mode: 775
    - require:
      - pkg: bind


/etc/logrotate.d/{{ map.service }}:
  file.managed:
    - source: salt://{{ map.config_source_dir }}/logrotate_bind
    - template: jinja
    - user: root
    - group: root
    - context:
        map: {{ map }}
{% endif %}

#}
