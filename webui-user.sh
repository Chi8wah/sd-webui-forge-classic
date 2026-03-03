#!/usr/bin/env bash

# export PYTHON=""
# export GIT=""
# export VENV_DIR=""

export COMMANDLINE_ARGS="--uv --port 9880 --cuda-malloc --listen --sage --flash"

# --xformers --sage --uv
# --pin-shared-memory --cuda-malloc --cuda-stream
# --skip-python-version-check --skip-torch-cuda-test --skip-version-check --skip-prepare-environment --skip-install

# 调用 Linux 环境下的主脚本 (假设你把前面的那个文件命名为了 webui.sh)
bash ./webui.sh