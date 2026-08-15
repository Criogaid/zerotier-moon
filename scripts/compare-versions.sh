#!/bin/bash

# 用法: ./compare-versions.sh <版本1> <版本2>

validate_version() {
    local version=$1
    if [[ ! $version =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
        echo "错误: 无效的版本格式 '$version'" >&2
        return 1
    fi
}

normalize_component() {
    local component=$1
    while [[ ${#component} -gt 1 && ${component:0:1} == 0 ]]; do
        component=${component:1}
    done
    printf '%s' "$component"
}

version_compare() {
    if ! validate_version "$1" || ! validate_version "$2"; then
        return 3
    fi

    local -a version1 version2
    local component1 component2
    local i length
    IFS=. read -r -a version1 <<< "$1"
    IFS=. read -r -a version2 <<< "$2"

    length=${#version1[@]}
    if (( ${#version2[@]} > length )); then
        length=${#version2[@]}
    fi

    for ((i = 0; i < length; i++)); do
        component1=$(normalize_component "${version1[i]:-0}")
        component2=$(normalize_component "${version2[i]:-0}")

        if (( ${#component1} > ${#component2} )); then
            return 1
        elif (( ${#component1} < ${#component2} )); then
            return 2
        elif [[ $component1 > $component2 ]]; then
            return 1
        elif [[ $component1 < $component2 ]]; then
            return 2
        fi
    done

    return 0
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    if [ "$#" -ne 2 ]; then
        echo "用法: $0 <版本1> <版本2>" >&2
        exit 1
    fi

    version_compare "$1" "$2"
    result=$?
    case $result in
        0) echo "$1 = $2" ;;
        1) echo "$1 > $2" ;;
        2) echo "$1 < $2" ;;
        3) echo "Error: Invalid version format"; exit 1 ;;
        *) echo "Error: Version comparison failed" >&2; exit 1 ;;
    esac
fi