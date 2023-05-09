# 文件结构
ultrasonic_sensor3_1.v  顶层模块，用于例化连接子模块端口

main.v  控制模块，控制整体的逻辑和检测部分

pulse.v  脉冲信号产生模块，可产生指定脉冲数和次数的脉冲控制信号

detected_count.v  检测计数模块，检测到位物体

spi.v  配置寄存器数据，发送数据至TUSS4470芯片
