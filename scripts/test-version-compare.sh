#!/bin/bash

# 版本比较测试脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 测试计数器
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# 测试函数
run_test() {
    local test_name=$1
    local version1=$2
    local version2=$3
    local expected=$4
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    echo -n "测试 $TESTS_TOTAL: $test_name ... "
    
    # 运行比较脚本
    ./compare-versions.sh "$version1" "$version2" > /dev/null 2>&1
    local actual=$?
    
    # 检查结果
    if [ $actual -eq $expected ]; then
        echo -e "${GREEN}通过${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}失败${NC}"
        echo "  期望: $expected, 实际: $actual"
        echo "  版本1: $version1, 版本2: $version2"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# 确保脚本可执行
chmod +x compare-versions.sh

echo "开始版本比较测试..."
echo "===================="

# 测试用例
run_test "相同版本" "1.14.0" "1.14.0" 0
run_test "主版本不同" "2.0.0" "1.14.0" 1
run_test "主版本不同(反向)" "1.14.0" "2.0.0" 2
run_test "次版本不同" "1.15.0" "1.14.0" 1
run_test "次版本不同(反向)" "1.14.0" "1.15.0" 2
run_test "修订版本不同" "1.14.1" "1.14.0" 1
run_test "修订版本不同(反向)" "1.14.0" "1.14.1" 2
run_test "不同长度版本" "1.14" "1.14.0" 0
run_test "不同长度版本(反向)" "1.14.0" "1.14" 0
run_test "三位数版本" "1.14.10" "1.14.2" 1
run_test "三位数版本(反向)" "1.14.2" "1.14.10" 2

echo "===================="
echo -e "测试完成: ${GREEN}$TESTS_PASSED 通过${NC}, ${RED}$TESTS_FAILED 失败${NC}, 总计 $TESTS_TOTAL"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}所有测试通过!${NC}"
    exit 0
else
    echo -e "${RED}有测试失败!${NC}"
    exit 1
fi