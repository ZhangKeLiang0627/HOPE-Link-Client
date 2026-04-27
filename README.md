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

# 安装X11相关依赖
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