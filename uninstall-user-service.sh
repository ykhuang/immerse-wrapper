#!/usr/bin/env bash
set -euo pipefail

service_name=immerse-wrapper.service
user_unit_dir="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
unit_target="$user_unit_dir/$service_name"

if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
  echo "Refusing to uninstall a user service as root; run this script as the WSL user." >&2
  exit 2
fi

systemctl --user disable --now "$service_name" >/dev/null 2>&1 || true
if [[ -f "$unit_target" ]]; then
  rm -f -- "$unit_target"
fi
systemctl --user daemon-reload
systemctl --user reset-failed "$service_name" >/dev/null 2>&1 || true

echo "removed_unit=$unit_target"
echo "The wheel, venv, configuration, logs, credentials, and runtime data were preserved."
