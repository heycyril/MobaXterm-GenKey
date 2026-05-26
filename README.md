# MobaXterm-GenKey
你懂的！！

## 演示地址
http://149.129.94.166:5000/


## 本地启动
需要安装Python3!!!
```
pip3 install --no-cache-dir -r requirements.txt
python3 app.py
```

## Docker
```
docker pull malaohu/mobaxterm-genkey
docker run -d -p 5001:5000 malaohu/mobaxterm-genkey
```


## 使用方法
访问：IP:5001

![image](https://img14.360buyimg.com/ddimg/jfs/t1/327451/37/1655/17390/68940230F93909c3f/80f2e5a285489ac1.jpg)

### 激活方式
直接放到软件目录即可！



核心内容来自：https://github.com/flygon2018/MobaXterm-keygen
详细介绍文章：https://51.ruyo.net/17008.html



在原来fork基础上新增如下：

1. app.py - Flask 应用优化
添加日志系统: 使用 Python logging 模块记录运行状态
环境变量配置: 支持通过 FLASK_HOST、FLASK_PORT、FLASK_DEBUG 环境变量配置
输入验证增强:
用户名长度限制 (50字符)
用户名非法字符过滤 (正则表达式)
版本号格式严格校验
用户数量范围限制 (1-999)
错误处理: 统一的 JSON 错误响应格式，添加 404/500 错误处理器
新增健康检查端点: /health 用于服务监控
代码规范: 函数名改为 snake_case，添加完整的 docstring
修复拼写错误: Persional -> Personal
2. start.sh - 启动脚本优化
PID 文件管理: 使用 PID 文件跟踪进程状态
依赖自动安装: 检测并自动安装缺失的 Python 依赖
优雅的健康检查: 可配置的重试次数和间隔
彩色输出: 使用颜色区分 INFO/WARN/ERROR 信息
进程异常检测: 检测进程异常退出并清理 PID 文件
3. stop.sh - 停止脚本优化
PID 文件优先: 优先使用 PID 文件定位进程
优雅停止: 先发送 SIGTERM，超时后强制 kill -9
进程存在性检查: 避免对已退出的进程执行操作
自动清理: 停止后自动删除 PID 文件
4. Dockerfile 优化
更新 Python 版本: 从 3.6-slim 升级到 3.12-slim
非 root 用户运行: 创建 appuser 用户，提升安全性
健康检查: 添加 HEALTHCHECK 指令
缓存优化: 分离依赖安装和代码复制层
LABEL 元数据: 添加维护者和描述信息
5. requirements.txt 优化
版本范围: 使用兼容的版本范围而非固定版本
添加 gunicorn: 为生产环境部署做准备
6. 新增 .gitignore
忽略 Python 缓存、日志文件、PID 文件、虚拟环境等


现在支持的用户数量范围是 1 - 99999


