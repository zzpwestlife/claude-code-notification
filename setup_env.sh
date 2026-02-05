#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== 环境检测与安装脚本 ===${NC}"

# 检测操作系统
OS="$(uname)"
echo -e "${YELLOW}检测到操作系统: $OS${NC}"

# 检测包管理器
PACKAGER=""
if [[ "$OS" == "Darwin" ]]; then
    if command -v brew &> /dev/null; then
        PACKAGER="brew"
    else
        echo -e "${YELLOW}未检测到 Homebrew，正在安装...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        PACKAGER="brew"
    fi
elif [[ "$OS" == "Linux" ]]; then
    if command -v apt-get &> /dev/null; then
        PACKAGER="apt-get"
    elif command -v yum &> /dev/null; then
        PACKAGER="yum"
    else
        echo -e "${RED}未支持的 Linux 发行版 (未找到 apt-get 或 yum)${NC}"
        exit 1
    fi
else
    echo -e "${RED}不支持的操作系统: $OS${NC}"
    exit 1
fi

echo -e "${GREEN}使用包管理器: $PACKAGER${NC}"

# 函数：检查并安装软件
check_and_install() {
    local cmd=$1
    local pkg=$2
    
    if command -v $cmd &> /dev/null; then
        echo -e "${GREEN}✅ $cmd 已安装${NC}"
    else
        echo -e "${YELLOW}⚠️ $cmd 未安装，正在安装...${NC}"
        if [[ "$PACKAGER" == "brew" ]]; then
            brew install $pkg
        elif [[ "$PACKAGER" == "apt-get" ]]; then
            sudo apt-get update && sudo apt-get install -y $pkg
        elif [[ "$PACKAGER" == "yum" ]]; then
            sudo yum install -y $pkg
        fi
        
        if command -v $cmd &> /dev/null; then
            echo -e "${GREEN}✅ $cmd 安装成功${NC}"
        else
            echo -e "${RED}❌ $cmd 安装失败，请手动安装${NC}"
        fi
    fi
}

# 1. 检查 Git
check_and_install git git

# 2. 检查 Node.js
check_and_install node node

# 3. 检查 npm (通常随 Node.js 安装)
if command -v npm &> /dev/null; then
    echo -e "${GREEN}✅ npm 已安装${NC}"
else
    echo -e "${RED}❌ npm 未找到，请检查 Node.js 安装${NC}"
fi

echo -e "${GREEN}=== 环境准备完成 ===${NC}"
echo -e "接下来请执行:"
echo -e "1. git clone <repo_url>"
echo -e "2. cd claude-code-notification"
echo -e "3. npm install"
echo -e "4. node setup-wizard.js"
