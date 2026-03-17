# GAAI framework installer
# Clones the GAAI framework, runs the install wizard, and cleans up
# Usage: gaai (run from a project directory)

gaai() {
  local repo_url="https://github.com/bketelsen/GAAI-framework.git"
  local tmp_dir="/tmp/gaai"

  git clone "$repo_url" "$tmp_dir" && \
    bash "$tmp_dir/.gaai/core/scripts/install.sh" --wizard && \
    rm -rf "$tmp_dir"
}
