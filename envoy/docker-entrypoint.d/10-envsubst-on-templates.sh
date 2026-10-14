#!/usr/bin/env sh

# makes copies of template files while replacing environment variables with their values.
# adapted from NGINX: https://github.com/nginxinc/docker-nginx/blob/master/entrypoint/20-envsubst-on-templates.sh
# Substitutes as envsubst does (${NAME} is replaced when NAME is set), but with sed, which
# the Envoy image already has, so nothing is installed when the container starts.

set -e

ME=$(basename $0)

substitute() {
  template=$1
  output=$2
  cp "$template" "$output.tmp"
  for name in $(grep -o '\${[A-Za-z_][A-Za-z0-9_]*}' "$template" | tr -d '${}' | sort -u); do
    # name is a shell identifier, matched above, so eval only reads that variable
    eval "is_set=\${$name+set}"
    [ "$is_set" = set ] || continue
    eval "value=\$$name"
    escaped=$(printf '%s' "$value" | sed 's/[\\|&]/\\&/g')
    sed -i "s|\${$name}|$escaped|g" "$output.tmp"
  done
  mv "$output.tmp" "$output"
}

auto_envsubst() {
  local template_dir="${ENVOY_ENVSUBST_TEMPLATE_DIR:-/etc/envoy/templates}"
  local suffix="${ENVOY_ENVSUBST_TEMPLATE_SUFFIX:-.template}"
  local output_dir="${NGINX_ENVSUBST_OUTPUT_DIR:-/etc/envoy}"

  local template relative_path output_path subdir
  [ -d "$template_dir" ] || return 0
  if [ ! -w "$output_dir" ]; then
    echo >&3 "$ME: ERROR: $template_dir exists, but $output_dir is not writable"
    return 0
  fi
  find "$template_dir" -follow -type f -name "*$suffix" -print | while read -r template; do
    relative_path="${template#$template_dir/}"
    output_path="$output_dir/${relative_path%$suffix}"
    subdir=$(dirname "$relative_path")
    # create a subdirectory where the template file exists
    mkdir -p "$output_dir/$subdir"
    echo >&3 "$ME: Running envsubst on $template to $output_path"
    substitute "$template" "$output_path"
  done
}

auto_envsubst

exit 0
