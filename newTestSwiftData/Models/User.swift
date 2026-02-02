//
//  User.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/30.
//

import Foundation
import SwiftData

/// SwiftData 用户模型
@Model
final class User {
    /// 用户 ID（主键，唯一）
    @Attribute(.unique) var id: Int
    
    /// 用户名（唯一）
    @Attribute(.unique) var username: String
    
    /// 密码（Mock 环境明文存储，真实环境需加密）
    var password: String
    
    /// 邮箱
    var email: String
    
    /// 创建时间
    var createdAt: Date
    
    /// 最后登录时间
    var lastLoginAt: Date?
    
    /// 是否是预置账号
    var isPreset: Bool
    
    /// 关联的 Token（一对多关系）
    @Relationship(deleteRule: .cascade, inverse: \Token.user)
    var tokens: [Token]?
    
    init(id: Int, username: String, password: String, email: String, isPreset: Bool = false) {
        self.id = id
        self.username = username
        self.password = password
        self.email = email
        self.createdAt = Date()
        self.isPreset = isPreset
        self.tokens = []
    }
    
    /// 更新最后登录时间
    func updateLastLogin() {
        self.lastLoginAt = Date()
    }
}

// MARK: - 扩展方法

extension User {
    /// 转换为 UserInfo
    func toUserInfo() -> UserInfo {
        return UserInfo(id: id, username: username, email: email)
    }
    
    /// 验证密码
    func validatePassword(_ password: String) -> Bool {
        return self.password == password
    }
}

