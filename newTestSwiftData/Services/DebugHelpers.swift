//
//  DebugHelpers.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/30.
//

import Foundation

/// 调试辅助函数 - 方便在 LLDB 中调用

/// 打印所有用户到控制台
func debugPrintUsers() {
    SwiftDataAuthService.shared.printAllUsers()
}

/// 获取所有用户
func debugGetUsers() -> [User] {
    return SwiftDataAuthService.shared.getAllUsers()
}

/// 获取所有 Token
func debugGetTokens() -> [Token] {
    return SwiftDataAuthService.shared.getAllTokens()
}

/// 打印用户数量
func debugUserCount() {
    let count = SwiftDataAuthService.shared.getAllUsers().count
    print("📊 当前数据库中有 \(count) 个用户")
}

/// 打印简化的用户列表
func debugListUsers() {
    let users = SwiftDataAuthService.shared.getAllUsers()
    print("\n👥 用户列表：")
    for (index, user) in users.enumerated() {
        print("[\(index + 1)] \(user.username) - \(user.password) - \(user.email)")
    }
    print("总共 \(users.count) 个用户\n")
}
