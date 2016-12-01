{% from "bind/map.jinja" import map with context %}

include:
  - bind

bind_dir_config:
  file.directory:
    - name: {{ map.dirs.config }}
    - user: root
    - group: {{ map.permissions.group }}
    - dir_mode: 2750
    - file_mode: 640
    - makedirs: True
    - recurse:
      - user
      - group
      - mode
    - require_in:
      - bind_install
    - watch_in:
      - bind_running

bind_dir_service:
  file.directory:
    - name: {{ map.dirs.service }}
    - user: {{ map.permissions.user }}
    - group: {{ map.permissions.group }}
    - dir_mode: {{ map.permissions.dir_mode }}
    - file_mode: {{ map.permissions.file_mode }}
    - makedirs: True
    - recurse:
      - user
      - group
      - mode
    - require_in:
      - bind_install
    - watch_in:
      - bind_running

bind_file_config:
  file.managed:
    - name: {{ map.dirs.config }}/{{ map.configs.named }}
    - source: 'salt://bind/files/common/{{ map.configs.named }}'
    - template: jinja
    - require:
      - file: bind_dir_config
    - watch_in:
      - bind_running

bind_file_options:
  file.managed:
    - name: {{ map.dirs.config }}/{{ map.configs.options }}
    - source: 'salt://bind/files/common/{{ map.configs.options }}'
    - template: jinja
    - require:
        - file: bind_dir_config
    - watch_in:
      - bind_running

{#
named_log_dir:
  file.directory:
    - name: {{ map.dirs.log }}:
    - user: root
    - group: {{ salt['pillar.get']('bind:config:group', map.group) }}
    - mode: 775
    - require:
      - pkg: bind


named_log_file:
  file.managed:
    - name: {{ map.dirs.log }}/query.log:
    - user: {{ salt['pillar.get']('bind:config:user', map.user) }}
    - group: {{ salt['pillar.get']('bind:config:group', map.group) }}
    - mode: 644
    - require:
      - file: named_log_dir

named_directory:
  file.directory:
    - name: {{ map.dirs.named }}
    - user: {{ salt['pillar.get']('bind:config:user', map.user) }}
    - group: {{ salt['pillar.get']('bind:config:group', map.group) }}
    - mode: 775
    - makedirs: True
    - require:
      - pkg: bind

bind_config:
  file.managed:
    - name: {{ map.config }}
    - source: 'salt://{{ map.config_source_dir }}/named.conf'
    - template: jinja
    - user: {{ salt['pillar.get']('bind:config:user', map.user) }}
    - group: {{ salt['pillar.get']('bind:config:group', map.group) }}
    - mode: {{ salt['pillar.get']('bind:config:mode', map.mode) }}
    - context:
        map: {{ map }}
    - require:
      - pkg: bind
    - watch_in:
      - service: bind

bind_local_config:
  file.managed:
    - name: {{ map.local_config }}
    - source: 'salt://{{ map.config_source_dir }}/named.conf.local'
    - template: jinja
    - user: {{ salt['pillar.get']('bind:config:user', map.user) }}
    - group: {{ salt['pillar.get']('bind:config:group', map.group) }}
    - mode: {{ salt['pillar.get']('bind:config:mode', '644') }}
    - context:
        map: {{ map }}
    - require:
      - pkg: bind
      - file: {{ map.log_dir }}/query.log
    - watch_in:
      - service: bind

{% if grains['os_family'] != 'Arch' %}
bind_default_config:
  file.managed:
    - name: {{ map.default_config }}
    - source: salt://{{ map.config_source_dir }}/default
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - watch_in:
      - service: bind_restart
{% endif %}

{% if grains['os_family'] == 'Debian' %}
bind_key_config:
  file.managed:
    - name: {{ map.key_config }}
    - source: 'salt://{{ map.config_source_dir }}/named.conf.key'
    - template: jinja
    - user: {{ salt['pillar.get']('bind:config:user', map.user) }}
    - group: {{ salt['pillar.get']('bind:config:group', map.group) }}
    - mode: {{ salt['pillar.get']('bind:config:mode', '644') }}
    - require:
      - pkg: bind
    - watch_in:
      - service: bind

bind_options_config:
  file.managed:
    - name: {{ map.options_config }}
    - source: 'salt://{{ map.config_source_dir }}/named.conf.options'
    - template: jinja
    - user: {{ salt['pillar.get']('bind:config:user', map.user) }}
    - group: {{ salt['pillar.get']('bind:config:group', map.group) }}
    - mode: {{ salt['pillar.get']('bind:config:mode', '644') }}
    - require:
      - pkg: bind
    - watch_in:
      - service: bind

bind_default_zones:
  file.managed:
    - name: {{ map.default_zones_config }}
    - source: 'salt://{{ map.config_source_dir }}/named.conf.default-zones'
    - template: jinja
    - user: {{ salt['pillar.get']('bind:config:user', map.user) }}
    - group: {{ salt['pillar.get']('bind:config:group', map.group) }}
    - mode: {{ salt['pillar.get']('bind:config:mode', '644') }}
    - require:
      - pkg: bind
    - watch_in:
      - service: bind

/etc/logrotate.d/{{ map.service }}:
  file.managed:
    - source: salt://{{ map.config_source_dir }}/logrotate_bind
    - template: jinja
    - user: root
    - group: root
    - context:
        map: {{ map }}
{% endif %}

{% for zone, zone_data in salt['pillar.get']('bind:configured_zones', {}).items() -%}
{%- set file = salt['pillar.get']("bind:available_zones:" + zone + ":file") %}
{% if file and zone_data['type'] == "master" -%}
zones-{{ zone }}:
  file.managed:
    - name: {{ map.named_directory }}/{{ file }}
    - source: 'salt://{{ map.zones_source_dir }}/{{ file }}'
    - template: jinja
    - user: {{ salt['pillar.get']('bind:config:user', map.user) }}
    - group: {{ salt['pillar.get']('bind:config:group', map.group) }}
    - mode: {{ salt['pillar.get']('bind:config:mode', '644') }}
    - watch_in:
      - service: bind
    - require:
      - file: named_directory

{% if zone_data['dnssec'] is defined and zone_data['dnssec'] -%}
signed-{{ zone }}:
  cmd.run:
    - cwd: {{ map.named_directory }}
    - name: zonesigner -zone {{ zone }} {{ file }}
    - prereq:
      - file: zones-{{ zone }}
{% endif %}

{% endif %}
{% endfor %}

{%- for view, view_data in salt['pillar.get']('bind:configured_views', {}).items() %}
{% for zone, zone_data in view_data.get('configured_zones', {}).items() -%}
{%- set file = salt['pillar.get']("bind:available_zones:" + zone + ":file") %}
{% if file and zone_data['type'] == "master" -%}
zones-{{ view }}-{{ zone }}:
  file.managed:
    - name: {{ map.named_directory }}/{{ file }}
    - source: 'salt://{{ map.zones_source_dir }}/{{ file }}'
    - template: jinja
    - user: {{ salt['pillar.get']('bind:config:user', map.user) }}
    - group: {{ salt['pillar.get']('bind:config:group', map.group) }}
    - mode: {{ salt['pillar.get']('bind:config:mode', '644') }}
    - watch_in:
      - service: bind
    - require:
      - file: named_directory

{% if zone_data['dnssec'] is defined and zone_data['dnssec'] -%}
signed-{{ view }}-{{ zone }}:
  cmd.run:
    - cwd: {{ map.named_directory }}
    - name: zonesigner -zone {{ zone }} {{ file }}
    - prereq:
      - file: zones-{{ view }}-{{ zone }}
{% endif %}

{% endif %}
{% endfor %}
{% endfor %}
#}
