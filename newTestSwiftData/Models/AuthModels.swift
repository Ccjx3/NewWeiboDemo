//
//  AuthModels.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/30.
//

import Foundation

// MARK: - Mock 用户模型

/// Mock 用户数据
struct MockUser {
    let id: Int
    let username: String
    let password: String
    let email: String
    let createdAt: Date
}

// MARK: - Token 模型

/// Token 类型
enum TokenType: String {
    case access = "access"
    case refresh = "refresh"
}

/// Token 信息
struct TokenInfo {
    let userId: Int
    let username: String
    let expiresAt: Date
    let type: TokenType
}

// MARK: - 响应模型

/// 用户信息
struct UserInfo: Codable {
    let id: Int
    let username: String
    let email: String
}

/// 登录响应
struct LoginResponse {
    let accessToken: String
    let refreshToken: String
    let user: UserInfo
}

/// 注册响应
struct RegisterResponse {
    let accessToken: String
    let refreshToken: String
    let user: UserInfo
}

// MARK: - 错误模型

/// 认证错误
enum AuthError: Error {
    case userNotFound
    case invalidPassword
    case userAlreadyExists
    case invalidEmail
    case passwordTooShort
    case networkError
    case tokenExpired
    case invalidToken
    
    var message: String {
        switch self {
        case .userNotFound:
            return "用户不存在"
        case .invalidPassword:
            return "密码错误"
        case .userAlreadyExists:
            return "用户名已存在"
        case .invalidEmail:
            return "邮箱格式不正确"
        case .passwordTooShort:
            return "密码长度不能少于6位"
        case .networkError:
            return "网络连接失败"
        case .tokenExpired:
            return "登录已过期，请重新登录"
        case .invalidToken:
            return "无效的登录凭证"
        }
    }
}

