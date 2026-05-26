#!/bin/bash
# ============================================================================
# MobaXterm Keygen - 停止脚本
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLASK_PORT=5001

echo "=============================================="
echo "  MobaXterm Keygen - 停止服务"
echo "=============================================="
echo ""

# 查找并停止 Flask 进程
echo "[INFO] 正在停止 MobaXterm Keygen..."
FLASK_PIDS=$(ps aux | grep "python3 app.py" | grep -v grep | awk '{print $2}')

if [ -z "$FLASK_PIDS" ]; then
    echo "[OK] MobaXterm Keygen 未运行"
else
    for PID in $FLASK_PIDS; do
        echo "  停止进程 PID: $PID"
        kill $PID 2>/dev/null
    done

    # 等待进程完全停止
    sleep 2

    # 检查是否还有残留进程
    REMAINING=$(ps aux | grep "python3 app.py" | grep -v grep | awk '{print $2}')
    if [ -n "$REMAINING" ]; then
        echo "[WARN] 强制终止残留进程..."
        for PID in $REMAINING; do
            kill -9 $PID 2>/dev/null
        done
    fi

    echo "[OK] MobaXterm Keygen 已停止"
fi

echo ""
echo "=============================================="
echo "  服务已停止"
echo "=============================================="
echo ""
echo "  日志文件: /tmp/mobaxterm-keygen.log"
echo ""
