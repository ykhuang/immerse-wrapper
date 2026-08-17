#!/usr/bin/env bash
set -euo pipefail

service_name=immerse-wrapper.service
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
release_unit="$script_dir/$service_name"
repository_unit="$script_dir/../packaging/systemd/$service_name"
venv_command="$HOME/.venvs/immerse-wrapper/bin/immerse-wrapper"
env_file="$HOME/.config/immerse-wrapper/immerse-wrapper.env"
work_dir="$HOME/.local/share/immerse-wrapper"
user_unit_dir="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
unit_target="$user_unit_dir/$service_name"
service_path="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin"
validation_root=""
enable_service=false

usage() {
  cat <<'EOF'
Usage: bash install-user-service.sh [--enable]

Install or update the ImmerseWrapper systemd user unit.

  --enable  Enable startup when the WSL user's systemd manager starts.
  -h, --help  Show this help.

Without --enable, the installer preserves the unit's current enabled/disabled
state and does not start the service.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --enable)
      enable_service=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

cleanup() {
  if [[ -n "$validation_root" && -d "$validation_root" \
    && "$(basename "$validation_root")" == immerse-wrapper-unit.* ]]; then
    rm -rf -- "$validation_root"
  fi
}
trap cleanup EXIT

if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
  echo "Refusing to install a user service as root; run this script as the WSL user." >&2
  exit 2
fi

if [[ -f "$release_unit" ]]; then
  unit_source=$release_unit
elif [[ -f "$repository_unit" ]]; then
  unit_source=$repository_unit
else
  echo "Service unit not found beside the installer or in the repository." >&2
  exit 2
fi

if [[ ! -x "$venv_command" ]]; then
  echo "Installed command is missing or not executable: $venv_command" >&2
  exit 2
fi
if [[ ! -f "$env_file" ]]; then
  echo "Explicit service configuration is missing: $env_file" >&2
  exit 2
fi

env_permissions=$(stat -c '%a' "$env_file")
if (( (8#$env_permissions & 077) != 0 )); then
  echo "Service configuration must not be accessible by group/others: $env_file" >&2
  echo "Run: chmod 600 $env_file" >&2
  exit 2
fi

if ! systemctl --user show-environment >/dev/null 2>&1; then
  echo "The systemd user manager is unavailable; confirm WSL systemd is enabled." >&2
  exit 2
fi

PATH="$service_path" "$venv_command" check-config --env-file "$env_file"
validation_root=$(mktemp -d -t immerse-wrapper-unit.XXXXXXXX)
install -m 0644 "$unit_source" "$validation_root/$service_name"
systemd-analyze --user verify "$validation_root/$service_name"

mkdir -p "$user_unit_dir" "$work_dir"
install -m 0644 "$unit_source" "$unit_target"
systemctl --user daemon-reload

if [[ "$enable_service" == true ]]; then
  systemctl --user enable "$service_name"
fi

loaded_state=$(systemctl --user show "$service_name" --property=LoadState --value)
enabled_state=$(systemctl --user is-enabled "$service_name" 2>/dev/null || true)
echo "installed_unit=$unit_target"
echo "load_state=$loaded_state"
echo "enabled_state=$enabled_state"
if [[ "$enable_service" == true ]]; then
  echo "The unit is enabled and will start when this WSL user's systemd manager starts."
else
  echo "The installer preserved the unit's enabled/disabled state."
fi
echo "Start it now with:"
echo "  systemctl --user start $service_name"
