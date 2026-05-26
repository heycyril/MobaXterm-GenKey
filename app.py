#!/usr/bin/env python3
"""MobaXterm License Key Generator - Flask Web Application"""

import os
import re
import logging
import zipfile
import io
from typing import Optional, Tuple, Dict, Any
from flask import Flask, request, send_file, make_response, jsonify, Response


logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__, static_folder='.')

HOST = os.environ.get('FLASK_HOST', '0.0.0.0')
PORT = int(os.environ.get('FLASK_PORT', 5001))
DEBUG = os.environ.get('FLASK_DEBUG', 'false').lower() == 'true'
MAX_USERNAME_LENGTH = 50
MAX_USER_COUNT = 99999

VariantBase64Table = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/='
VariantBase64Dict = {i: VariantBase64Table[i] for i in range(len(VariantBase64Table))}
VariantBase64ReverseDict = {VariantBase64Table[i]: i for i in range(len(VariantBase64Table))}


def variant_base64_encode(bs: bytes) -> bytes:
    """Variant Base64 编码实现"""
    blocks_count, left_bytes = divmod(len(bs), 3)
    result = []

    for i in range(blocks_count):
        coding_int = int.from_bytes(bs[3 * i:3 * i + 3], 'little')
        result.extend([
            VariantBase64Dict[coding_int & 0x3f],
            VariantBase64Dict[(coding_int >> 6) & 0x3f],
            VariantBase64Dict[(coding_int >> 12) & 0x3f],
            VariantBase64Dict[(coding_int >> 18) & 0x3f]
        ])

    if left_bytes:
        coding_int = int.from_bytes(bs[3 * blocks_count:], 'little')
        result.append(VariantBase64Dict[coding_int & 0x3f])
        result.append(VariantBase64Dict[(coding_int >> 6) & 0x3f])
        if left_bytes == 2:
            result.append(VariantBase64Dict[(coding_int >> 12) & 0x3f])

    return ''.join(result).encode()


def encrypt_bytes(key: int, bs: bytes) -> bytes:
    """XOR 加密字节数据"""
    result = bytearray(len(bs))
    for i, byte in enumerate(bs):
        result[i] = byte ^ ((key >> 8) & 0xff)
        key = result[i] & key | 0x482D
    return bytes(result)


class LicenseType:
    """许可证类型枚举"""
    Professional = 1
    Educational = 3
    Personal = 4


def create_error_response(error: str, message: str, status_code: int) -> Tuple[Response, int]:
    """创建统一格式的错误响应"""
    return jsonify({'error': error, 'message': message}), status_code


def generate_license_in_memory(license_type: int, count: int, username: str,
                                major_version: int, minor_version: int) -> io.BytesIO:
    """
    在内存中生成许可证 ZIP 文件。

    Args:
        license_type: 许可证类型
        count: 用户数量
        username: 用户名
        major_version: 主版本号
        minor_version: 次版本号

    Returns:
        包含许可证文件的 BytesIO 对象
    """
    if count < 0:
        raise ValueError("用户数量不能为负数")

    license_string = f'{license_type}#{username}|{major_version}{minor_version}#{count}#{major_version}{minor_version}{minor_version}#0#0#0#'
    encoded_license = variant_base64_encode(
        encrypt_bytes(0x787, license_string.encode())
    ).decode()

    memory_file = io.BytesIO()
    with zipfile.ZipFile(memory_file, 'w', zipfile.ZIP_DEFLATED) as zf:
        zf.writestr('Pro.key', data=encoded_license)

    memory_file.seek(0)
    return memory_file


def validate_username(username: str) -> Tuple[bool, str]:
    """
    验证用户名格式。

    Returns:
        (is_valid: bool, error_message: str)
    """
    if not username or not username.strip():
        return False, "用户名不能为空"

    username = username.strip()

    if len(username) > MAX_USERNAME_LENGTH:
        return False, f"用户名长度不能超过 {MAX_USERNAME_LENGTH} 个字符"

    if not re.match(r'^[\w\s\u4e00-\u9fff\.\-\_]+$', username):
        return False, "用户名包含非法字符"

    return True, ""


def validate_version(version: str) -> Tuple[bool, str, int, int]:
    """
    验证版本号格式。

    Returns:
        (is_valid: bool, error_message: str, major: int, minor: int)
    """
    if not version:
        return False, "版本号不能为空", 0, 0

    version_pattern = r'^(\d+)\.(\d+)(?:\.\d+)*$'
    match = re.match(version_pattern, version)

    if not match:
        return False, "版本号格式不正确，应为 '主版本.次版本' (例如: 25.2)", 0, 0

    major, minor = int(match.group(1)), int(match.group(2))

    if not (0 <= major <= 99):
        return False, "主版本号必须在 0-99 之间", 0, 0

    if not (0 <= minor <= 99):
        return False, "次版本号必须在 0-99 之间", 0, 0

    return True, "", major, minor


@app.route('/')
def index():
    """提供 Web 界面"""
    return send_file('index.html')


@app.route('/health')
def health_check():
    """健康检查端点"""
    return jsonify({
        'status': 'healthy',
        'service': 'MobaXterm Keygen'
    }), 200


@app.route('/gen')
def generate_license():
    """
    生成许可证密钥。

    Query Parameters:
        name: 用户名 (必需)
        ver: 版本号 (必需，格式: 主版本.次版本)
        count: 用户数量 (可选，默认 1)
    """
    try:
        name = request.args.get('name', '').strip()
        version = request.args.get('ver', '').strip()

        if not name or not version:
            return create_error_response(
                '缺少必需参数',
                "必须提供 'name' 和 'ver' 参数",
                400
            )

        is_valid, error_msg = validate_username(name)
        if not is_valid:
            return create_error_response('用户名无效', error_msg, 400)

        is_valid, error_msg, major_ver, minor_ver = validate_version(version)
        if not is_valid:
            return create_error_response('版本号无效', error_msg, 400)

        try:
            count = int(request.args.get('count', '1'))
            if not (1 <= count <= MAX_USER_COUNT):
                return create_error_response(
                    '用户数量无效',
                    f"用户数量必须在 1-{MAX_USER_COUNT} 之间",
                    400
                )
        except ValueError:
            return create_error_response('用户数量无效', "用户数量必须是整数", 400)

        logger.info(f"生成许可证: name={name}, version={version}, count={count}")

        license_stream = generate_license_in_memory(
            license_type=LicenseType.Professional,
            count=count,
            username=name,
            major_version=major_ver,
            minor_version=minor_ver
        )

        return send_file(
            license_stream,
            mimetype='application/zip',
            as_attachment=True,
            download_name=f'{name}_license.mxtpro'
        )

    except Exception as e:
        logger.error(f"生成许可证时发生错误: {str(e)}", exc_info=True)
        return create_error_response(
            '服务器内部错误',
            '生成许可证时发生错误，请稍后重试',
            500
        )


@app.errorhandler(404)
def not_found(error):
    """处理 404 错误"""
    return create_error_response('未找到', '请求的资源不存在', 404)


@app.errorhandler(500)
def internal_error(error):
    """处理 500 错误"""
    logger.error(f"服务器内部错误: {str(error)}")
    return create_error_response('服务器内部错误', '服务器发生错误，请稍后重试', 500)


if __name__ == '__main__':
    logger.info(f"启动 MobaXterm Keygen 服务...")
    logger.info(f"Host: {HOST}, Port: {PORT}, Debug: {DEBUG}")
    app.run(host=HOST, port=PORT, debug=DEBUG)

