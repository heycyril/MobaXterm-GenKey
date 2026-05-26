#!/bin/bash
# ============================================================================
# MobaXterm Keygen - 启动脚本
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLASK_PORT=5001

echo "=============================================="
echo "  MobaXterm Keygen - 启动服务"
echo "=============================================="
echo ""

# 检查 Flask 是否已在运行
if curl -s http://127.0.0.1:${FLASK_PORT}/ > /dev/null 2>&1; then
    echo "[OK] MobaXterm Keygen 已在运行 (端口 ${FLASK_PORT})"
else
    echo "[INFO] 启动 MobaXterm Keygen..."
    cd "$SCRIPT_DIR"
    nohup python3 app.py > /tmp/mobaxterm-keygen.log 2>&1 &
    FLASK_PID=$!

    # 等待 Flask 启动
    echo "[INFO] 等待服务启动..."
    for i in {1..10}; do
        if curl -s http://127.0.0.1:${FLASK_PORT}/ > /dev/null 2>&1; then
            echo "[OK] MobaXterm Keygen 启动成功 (PID: $FLASK_PID)"
            break
        fi
        sleep 1
    done

    if ! curl -s http://127.0.0.1:${FLASK_PORT}/ > /dev/null 2>&1; then
        echo "[ERROR] 启动失败，请检查日志: /tmp/mobaxterm-keygen.log"
        exit 1
    fi
fi

echo ""
echo "=============================================="
echo "  启动完成！"
echo "=============================================="
echo ""
echo "  访问地址:"
echo "    http://localhost:${FLASK_PORT}"
echo "    http://服务器IP:${FLASK_PORT}"
echo ""
echo "  日志文件: /tmp/mobaxterm-keygen.log"
echo ""
echo "  停止服务:"
echo "    $SCRIPT_DIR/stop.sh"
echo ""
