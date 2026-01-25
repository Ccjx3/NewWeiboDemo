#!/bin/bash

# CocoaPods 权限修复脚本
# 用于修复 "Operation not permitted" 错误

echo "🔧 开始修复 CocoaPods 权限问题..."

# 1. 清理 CocoaPods 缓存
echo "📦 清理 CocoaPods 缓存..."
rm -rf ~/Library/Caches/CocoaPods
rm -rf ~/.cocoapods/repos

# 2. 重新创建缓存目录
echo "📁 重新创建缓存目录..."
mkdir -p ~/Library/Caches/CocoaPods
mkdir -p ~/.cocoapods/repos

# 3. 设置正确的权限
echo "🔐 设置权限..."
chmod -R 755 ~/Library/Caches/CocoaPods
chmod -R 755 ~/.cocoapods

# 4. 清理项目中的 Pods
echo "🧹 清理项目 Pods..."
cd /Users/cjx/Code/SwiftLearning/newTestSwiftData
rm -rf Pods
rm -rf Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData/newTestSwiftData-*

# 5. 重新安装 Pods（不使用缓存）
echo "📥 重新安装 Pods..."
pod install --no-repo-update

echo "✅ 修复完成！"
echo ""
echo "📝 接下来的步骤："
echo "1. 关闭 Xcode"
echo "2. 打开 newTestSwiftData.xcworkspace"
echo "3. Clean Build Folder (Shift + Cmd + K)"
echo "4. 重新编译项目"

