{% from "bind/map.jinja" import map with context %}

include:
  - bind

{% for dir_name, dir_opts in map.dirs.items() %}

{{ dir_name }}:
  file.directory:
    - user: {{ dir_opts.user|default( map.user ) }}
    - group: {{ dir_opts.group|default( map.group ) }}
    - mode: {{ dir_opts.mode|default( map.modes.dir ) }}

    - makedirs: true

    - require:
      - bind_install

    - require_in:
      - service: bind_running

    - watch_in:
      - service: bind_running

{% for file_name, file_opts in (dir_opts.files|default( {} )).items() %}
{{ dir_name }}/{{ file_name }}:
  file.managed:
    - source: {{ map.template_dir }}/{{ file_opts.source|default( file_name ) }}
    - template: {{ file_opts.template|default( 'jinja' ) }}

    - user: {{ file_opts.user|default( map.user ) }}
    - group: {{ file_opts.group|default( map.group ) }}
    - mode: {{ file_opts.mode|default( map.modes.file ) }}

    - require:
      - {{ dir_name }}

    - require_in:
      - service: bind_running

    - watch_in:
      - service: bind_running

{% endfor %}
{% endfor %}


{% for key_name, key_opts in salt['pillar.get']('bind:keys', {}).items() %}
{{ map.keys_dir }}/{{ key_name }}.{{ map.key_extension }}:
  file.managed:
    - source: "salt://bind/files/common/key_file"
    - template: jinja
    - context:
        key_name: {{ key_name }}
        key_opts: {{ key_opts }}

    - user: {{ map.user }}
    - group: {{ map.group }}
    - mode: 600

    - require:
      - {{ map.keys_dir }}

    - require_in:
      - service: bind_running

    - watch_in:
      - service: bind_running

{% endfor %}

{% for zone_name, zone_opts in salt['pillar.get']('bind:zones', {}).items() %}
{% if zone_name != '.' and not (zone_opts['type'] in ['forward', 'slave']) %}
{% set is_master = zone_opts['type'] in ['delegation-only', 'master', 'redirect'] %}
{% set is_dynamic = ('none' not in zone_opts['allow-update']|default(['none'])) or (zone_opts['update-policy'] is defined) %}
{% set dir_name = map.dynamic_dir if is_dynamic else map.service_dir %}
{{ dir_name }}/named.{{ zone_name }}:
  file.managed:
{% if is_master %}
    - source: "salt://bind/files/common/zone_file"
    - template: jinja
    - replace: {{ not is_dynamic }}
    - context:
        origin: {{ zone_name }}
        authority: {{ zone_opts.authority|default({}) }}
        records: {{ zone_opts.records|default({}) }}
        is_dynamic: {{ is_dynamic }}
{% endif %}

    - user: {{ map.user }}
    - group: {{ map.group }}
    - mode: 600

    - require:
      - {{ dir_name }}

    - require_in:
      - service: bind_running

    - watch_in:
      - service: bind_running

{% endif %}
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
    - source: {{ map.template_dir }}/logrotate_bind
    - template: jinja
    - user: root
    - group: root
    - context:
        map: {{ map }}
{% endif %}

#}
