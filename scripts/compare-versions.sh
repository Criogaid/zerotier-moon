#!/bin/bash

# 版本比较脚本
# 用法: ./compare-versions.sh <版本1> <版本2>
# 返回: 0 如果版本1等于版本2, 1 如果版本1大于版本2, 2 如果版本1小于版本2

# 验证版本格式
validate_version() {
    local version=$1
    # 检查版本格式是否为数字.数字.数字或数字.数字
    if [[ ! $version =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
        echo "错误: 无效的版本格式 '$version'" >&2
        return 1
    fi
    return 0
}

version_compare() {
    # 验证输入
    if ! validate_version "$1" || ! validate_version "$2"; then
        return 3
    fi
    
    if [[ $1 == $2 ]]; then
        return 0
    fi
    
    local IFS=.
    local i ver1=($1) ver2=($2)
    
    # 填充零使版本号长度相同
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done
    for ((i=${#ver2[@]}; i<${#ver1[@]}; i++)); do
        ver2[i]=0
    done
    
    for ((i=0; i<${#ver1[@]}; i++)); do
        if [[ -z ${ver2[i]} ]]; then
            return 1
        fi
        
        if ((10#${ver1[i]} > 10#${ver2[i]})); then
            return 1
        fi
        
        if ((10#${ver1[i]} < 10#${ver2[i]})); then
            return 2
        fi
    done
    return 0
}

# 如果脚本被直接执行
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    if [ $# -ne 2 ]; then
        echo "用法: $0 <版本1> <版本2>"
        exit 1
    fi
    
    version_compare $1 $2
    case $? in
        0) echo "$1 = $2"; exit 0;;
        1) echo "$1 > $2"; exit 1;;
        2) echo "$1 < $2"; exit 2;;
    esac
fi