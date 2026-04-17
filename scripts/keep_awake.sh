#!/bin/bash
# keep_awake.sh - 保持屏幕开启指定时间

DURATION=${1:-36000}  # 默认10小时（36000秒），可传入参数
END_TIME=$(($(date +%s) + DURATION))

echo "保持屏幕开启 $(($DURATION / 60)) 分钟... 按 Ctrl+C 停止"

while [ $(date +%s) -lt $END_TIME ]; do
    # 微动鼠标 1 像素再移回去，肉眼不可见
    xdotool mousemove_relative -- 1 0
    sleep 0.1
    xdotool mousemove_relative -- -1 0
    
    # 每 30 秒动一次（调整间隔可改变"活跃度"）
    sleep 30
done

echo "时间到，停止干扰"
