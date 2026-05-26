#!/bin/bash
# ============================================================================
# MobaXterm Keygen - 停止脚本
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="${SCRIPT_DIR}/app.pid"
GRACEFUL_TIMEOUT=5

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

# 检查进程是否存在
is_process_running() {
    local pid=$1
    kill -0 "$pid" 2>/dev/null
}

# 优雅停止
graceful_stop() {
    local pid=$1
    log_info "发送 SIGTERM 信号到进程 $pid..."
    kill "$pid" 2>/dev/null || true

    # 等待进程退出
    local count=0
    while [ $count -lt $GRACEFUL_TIMEOUT ]; do
        if ! is_process_running "$pid"; then
            return 0
        fi
        sleep 1
        count=$((count + 1))
    done

    return 1
}

# 强制停止
force_stop() {
    local pid=$1
    log_warn "进程未在 $GRACEFUL_TIMEOUT 秒内停止，强制终止..."
    kill -9 "$pid" 2>/dev/null || true
    sleep 1
}

# 清理 PID 文件
cleanup_pid_file() {
    if [ -f "$PID_FILE" ]; then
        rm -f "$PID_FILE"
        log_info "已清理 PID 文件"
    fi
}

# 主逻辑
main() {
    echo "=============================================="
    echo "  MobaXterm Keygen - 停止服务"
    echo "=============================================="
    echo ""

    # 检查 PID 文件
    if [ ! -f "$PID_FILE" ]; then
        log_warn "PID 文件不存在，尝试查找进程..."

        # 通过进程名查找
        PIDS=$(pgrep -f "python3.*app.py" 2>/dev/null || true)

        if [ -z "$PIDS" ]; then
            log_info "MobaXterm Keygen 未运行"
            exit 0
        fi

        log_warn "发现运行中的进程: $PIDS"
        for PID in $PIDS; do
            if graceful_stop "$PID"; then
                log_info "进程 $PID 已停止"
            else
                force_stop "$PID"
                log_info "进程 $PID 已强制停止"
            fi
        done
    else
        PID=$(cat "$PID_FILE")

        if ! is_process_running "$PID"; then
            log_warn "进程 $PID 不存在（可能已异常退出）"
            cleanup_pid_file
            exit 0
        fi

        log_info "正在停止 MobaXterm Keygen (PID: $PID)..."

        if graceful_stop "$PID"; then
            log_info "MobaXterm Keygen 已成功停止"
        else
            force_stop "$PID"
            log_info "MobaXterm Keygen 已强制停止"
        fi

        cleanup_pid_file
    fi

    echo ""
    echo "=============================================="
    echo "  服务已停止"
    echo "=============================================="
    echo ""
}

main
