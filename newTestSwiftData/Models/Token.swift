//
//  Token.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/30.
//

import Foundation
import SwiftData

/// SwiftData Token 模型
@Model
final class Token {
    /// Token 字符串（主键，唯一）
    @Attribute(.unique) var tokenString: String
    
    /// Token 类型（access 或 refresh）
    var type: String
    
    /// 过期时间
    var expiresAt: Date
    
    /// 创建时间
    var createdAt: Date
    
    /// 关联的用户（多对一关系）
    var user: User?
    
    init(tokenString: String, type: TokenType, expiresAt: Date, user: User) {
        self.tokenString = tokenString
        self.type = type.rawValue
        self.expiresAt = expiresAt
        self.createdAt = Date()
        self.user = user
    }
    
    /// 检查 Token 是否过期
    var isExpired: Bool {
        return expiresAt < Date()
    }
    
    /// 检查 Token 是否有效
    var isValid: Bool {
        return !isExpired
    }
    
    /// 获取 Token 类型枚举
    var tokenType: TokenType? {
        return TokenType(rawValue: type)
    }
}

// MARK: - 扩展方法

extension Token {
    /// 转换为 TokenInfo
    func toTokenInfo() -> TokenInfo? {
        guard let user = user, let tokenType = tokenType else {
            return nil
        }
        return TokenInfo(
            userId: user.id,
            username: user.username,
            expiresAt: expiresAt,
            type: tokenType
        )
    }
}

