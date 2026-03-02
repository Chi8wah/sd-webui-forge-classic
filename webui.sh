#!/usr/bin/env bash

# 发生错误并展示输出日志的帮助函数（对应原脚本的 :show_stdout_stderr 和 :show_stderr）
show_stdout_stderr() {
    local exit_code=$1
    echo ""
    echo "exit code: $exit_code"

    # 如果 stdout.txt 存在且大小大于0
    if [ -s tmp/stdout.txt ]; then
        echo ""
        echo "stdout:"
        cat tmp/stdout.txt
    fi

    # 如果 stderr.txt 存在且大小大于0
    if [ -s tmp/stderr.txt ]; then
        echo ""
        echo "stderr:"
        cat tmp/stderr.txt
    fi

    echo ""
    echo "Launch Unsuccessful! Exiting..."
    echo "Press any key to continue..."
    read -n 1 -s -r
    exit "$exit_code"
}

# 检查是否存放了设置脚本，将 .bat 映射为标准的 .sh
if [ -f "webui.settings.sh" ]; then
    source webui.settings.sh
fi

# 设置环境变量默认值
if [ -z "$PYTHON" ]; then
    PYTHON="python3" # 在Linux中通常默认使用 python3
fi

if [ -n "$GIT" ]; then
    export GIT_PYTHON_GIT_EXECUTABLE="$GIT"
fi

if [ -z "$VENV_DIR" ]; then
    # 获取当前脚本所在绝对路径，等效于批处理中的 %~dp0
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    VENV_DIR="${SCRIPT_DIR}/venv"
fi

export SD_WEBUI_RESTART="tmp/restart"
export ERROR_REPORTING="FALSE"

# 创建 tmp 文件夹，忽略报错（对应 mkdir tmp 2>NUL）
mkdir -p tmp 2>/dev/null

# 测试 Python 环境
if uv help python >tmp/stdout.txt 2>tmp/stderr.txt; then
    : # 成功，继续往下执行
elif "$PYTHON" -c "" >tmp/stdout.txt 2>tmp/stderr.txt; then
    : # 成功，继续往下执行
else
    err_code=$?
    echo "Couldn't launch python"
    show_stdout_stderr "$err_code"
fi

# 测试 PIP 环境
if uv help pip >tmp/stdout.txt 2>tmp/stderr.txt; then
    : # 成功，继续往下执行
elif "$PYTHON" -m pip --help >tmp/stdout.txt 2>tmp/stderr.txt; then
    : # 成功，继续往下执行
else
    err_code=$?
    echo "Couldn't launch pip"
    show_stdout_stderr "$err_code"
fi

# 虚拟环境 (VENV) 的创建与激活 (对应 :start_venv 等逻辑)
if [ "$VENV_DIR" != "-" ] &&[ "$SKIP_VENV" != "1" ]; then
    # 在 Linux 中，虚拟环境的 Python 可执行文件存放在 bin 目录下
    if [ ! -f "$VENV_DIR/bin/python" ]; then
        # 获取 Python 的绝对路径
        PYTHON_FULLNAME=$("$PYTHON" -c "import sys; print(sys.executable)")
        echo "Creating venv in directory $VENV_DIR using python $PYTHON_FULLNAME"
        
        # 创建虚拟环境
        if ! "$PYTHON_FULLNAME" -m venv "$VENV_DIR" >tmp/stdout.txt 2>tmp/stderr.txt; then
            err_code=$?
            echo "Unable to create venv in directory \"$VENV_DIR\""
            show_stdout_stderr "$err_code"
        fi

        # 升级 pip
        if ! "$VENV_DIR/bin/python" -m pip install --upgrade pip; then
            echo "Warning: Failed to upgrade PIP version"
        fi
    fi

    # 激活虚拟环境 (对应 :activate_venv)
    PYTHON="$VENV_DIR/bin/python"
    source "$VENV_DIR/bin/activate"
    echo "venv $PYTHON"
fi

# 启动和重启主逻辑 (对应 :launch)
# 使用 while 循环来替代原版不断检测 tmp/restart 并 goto 回调的逻辑
while true; do
    "$PYTHON" launch.py "$@"  # $@ 对应批处理的 %*
    
    # 检测是否要求重启
    if [ -f "tmp/restart" ]; then
        continue
    else
        break
    fi
done

echo "Press any key to continue..."
read -n 1 -s -r
exit 0