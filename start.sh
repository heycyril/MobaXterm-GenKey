#!/bin/bash
# ============================================================================
# MobaXterm Keygen - 启动脚本
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLASK_PORT="${FLASK_PORT:-5001}"
FLASK_HOST="${FLASK_HOST:-0.0.0.0}"
PID_FILE="${SCRIPT_DIR}/app.pid"
LOG_FILE="${SCRIPT_DIR}/app.log"
MAX_RETRIES=15
RETRY_INTERVAL=1

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查 Python 是否安装
check_python() {
    if ! command -v python3 &> /dev/null; then
        log_error "Python3 未安装，请先安装 Python3"
        exit 1
    fi
}

# 检查依赖是否安装
check_dependencies() {
    if ! python3 -c "import flask" 2>/dev/null; then
        log_warn "Flask 未安装，正在安装依赖..."
        cd "$SCRIPT_DIR"
        pip3 install -r requirements.txt || {
            log_error "依赖安装失败"
            exit 1
        }
        log_info "依赖安装成功"
    fi
}

# 检查服务是否已在运行
is_running() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            return 0
        else
            # PID 文件存在但进程不存在，清理
            rm -f "$PID_FILE"
            return 1
        fi
    fi
    return 1
}

# 健康检查
health_check() {
    curl -s "http://127.0.0.1:${FLASK_PORT}/health" > /dev/null 2>&1
}

# 启动服务
start_service() {
    log_info "启动 MobaXterm Keygen..."

    cd "$SCRIPT_DIR"

    # 设置环境变量
    export FLASK_PORT
    export FLASK_HOST
    export FLASK_DEBUG="${FLASK_DEBUG:-false}"

    # 后台启动
    nohup python3 app.py >> "$LOG_FILE" 2>&1 &
    local pid=$!
    echo $pid > "$PID_FILE"

    log_info "进程已启动 (PID: $pid)"
    log_info "等待服务就绪..."

    # 等待服务启动
    local count=0
    while [ $count -lt $MAX_RETRIES ]; do
        if health_check; then
            log_info "服务启动成功!"
            return 0
        fi

        # 检查进程是否还在运行
        if ! kill -0 "$pid" 2>/dev/null; then
            log_error "进程异常退出，请查看日志: $LOG_FILE"
            rm -f "$PID_FILE"
            return 1
        fi

        count=$((count + 1))
        sleep $RETRY_INTERVAL
    done

    log_error "服务启动超时"
    rm -f "$PID_FILE"
    return 1
}

# 主逻辑
main() {
    echo "=============================================="
    echo "  MobaXterm Keygen - 启动服务"
    echo "=============================================="
    echo ""

    check_python
    check_dependencies

    if is_running; then
        local pid=$(cat "$PID_FILE")
        log_warn "MobaXterm Keygen 已在运行 (PID: $pid, 端口: ${FLASK_PORT})"
        echo ""
        echo "  如需重启，请先执行: $SCRIPT_DIR/stop.sh"
        exit 0
    fi

    if start_service; then
        echo ""
        echo "=============================================="
        echo "  启动完成！"
        echo "=============================================="
        echo ""
        echo "  访问地址:"
        echo "    http://localhost:${FLASK_PORT}"
        echo "    http://服务器IP:${FLASK_PORT}"
        echo ""
        echo "  管理命令:"
        echo "    查看日志: tail -f $LOG_FILE"
        echo "    停止服务: $SCRIPT_DIR/stop.sh"
        echo "    查看状态: ps aux | grep app.py"
        echo ""
    else
        log_error "启动失败，请检查日志: $LOG_FILE"
        exit 1
    fi
}

main
