{% from "bind/map.jinja" import map with context %}

bind_install:
  pkg.installed:
    - pkgs: {{ map.pkgs|json }}
