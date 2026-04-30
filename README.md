# HOPE-Link-Client

# by Hugo@kkl


## Install

```shell
# 创建python虚拟环境
conda create -n pyside6 python=3.11

# 激活环境
conda activate pyside6

# 安装pyside6组件
pip install pyside6

# 安装pyserial
pip install pyserial

# Ubuntu安装X11相关依赖
sudo apt install libxcb-cursor0 libxcb-xinerama0 libxcb-randr0 libxcb-render0 libxcb-shape0 libxcb-xfixes0 libxcb-xkb-dev libxkbcommon-x11-0
```

- thanks：https://www.cnblogs.com/mthoutai/p/19613677


## Ubuntu的Serial权限问题

> Linux报错没有打开串口权限`/dev/ttyACM0`，`PermissionError: [Errno 13] Permission denied: ‘/dev/ttyACM0’`


```shell
# 查看系统用户
whoami
# hugokkl

# 加用户权限组
sudo usermod -aG dialout hugokkl

# 然后重启系统，即可
```

## Pack

```shell
pip install pyinstaller

pyinstaller --onefile --name="HOPE-Link-Client" --icon=icon.ico  --collect-all PySide6 main.py

# 不带窗体调试
pyinstaller --onefile --windowed --name="HOPE-Link-Client" --icon=icon.ico  --collect-all PySide6 main.py

# 生成exe后，将其放到project根目录下，即可双击启动！
```

## 关于MacOS串口传输拆包问题

相同的下位机，在实测环境波特率为`921600`，串口转ttl为`CH340`下，Windows/Ubuntu能够正常图传；而MacOS会出现拆包现象，图片帧数据不完整，寻找包头或者包尾失败，导致图片传输失败。

经过实测，设置波特率为`460800`，能够正常图传。

> btw，不知道是WCH驱动对Mac的支持差，还是Mac本身的串口机制就有问题，总之很sad！
