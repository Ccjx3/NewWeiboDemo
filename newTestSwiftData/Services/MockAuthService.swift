//
//  MockAuthService.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/30.
//

import Foundation

/// Mock 认证服务 - 模拟后端认证接口
class MockAuthService {
    static let shared = MockAuthService()
    
    // MARK: - Mock 用户数据库
    
    private var mockUsers: [String: MockUser] = [
        "admin": MockUser(
            id: 1,
            username: "admin",
            password: "123456",
            email: "admin@example.com",
            createdAt: Date()
        ),
        "test": MockUser(
            id: 2,
            username: "test",
            password: "123456",
            email: "test@example.com",
            createdAt: Date()
        )
    ]
    
    // MARK: - Token 存储
    
    /// 活跃的 Token（模拟服务端 Token 存储）
    private var activeTokens: [String: TokenInfo] = [:]
    
    /// 下一个用户 ID
    private var nextUserId: Int = 3
    
    private init() {}
    
    // MARK: - 登录
    
    /// 登录
    /// - Parameters:
    ///   - username: 用户名
    ///   - password: 密码
    ///   - completion: 完成回调
    func login(username: String, password: String, completion: @escaping (Result<LoginResponse, AuthError>) -> Void) {
        // 模拟网络延迟
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.8) {
            // 查找用户
            guard let user = self.mockUsers[username] else {
                DispatchQueue.main.async {
                    completion(.failure(.userNotFound))
                }
                return
            }
            
            // 验证密码
            guard password == user.password else {
                DispatchQueue.main.async {
                    completion(.failure(.invalidPassword))
                }
                return
            }
            
            // 生成 Token
            let accessToken = self.generateToken(userId: user.id, username: user.username, type: .access)
            let refreshToken = self.generateToken(userId: user.id, username: user.username, type: .refresh)
            
            // 保存 Token 到模拟服务端
            self.activeTokens[accessToken] = TokenInfo(
                userId: user.id,
                username: user.username,
                expiresAt: Date().addingTimeInterval(30 * 60), // 30分钟
                type: .access
            )
            
            self.activeTokens[refreshToken] = TokenInfo(
                userId: user.id,
                username: user.username,
                expiresAt: Date().addingTimeInterval(7 * 24 * 60 * 60), // 7天
                type: .refresh
            )
            
            // 返回响应
            let response = LoginResponse(
                accessToken: accessToken,
                refreshToken: refreshToken,
                user: UserInfo(
                    id: user.id,
                    username: user.username,
                    email: user.email
                )
            )
            
            DispatchQueue.main.async {
                print("✅ Mock 登录成功: \(user.username)")
                completion(.success(response))
            }
        }
    }
    
    // MARK: - 注册
    
    /// 注册
    /// - Parameters:
    ///   - username: 用户名
    ///   - password: 密码
    ///   - email: 邮箱
    ///   - completion: 完成回调
    func register(username: String, password: String, email: String, completion: @escaping (Result<RegisterResponse, AuthError>) -> Void) {
        // 模拟网络延迟
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.8) {
            // 检查用户名是否已存在
            if self.mockUsers[username] != nil {
                DispatchQueue.main.async {
                    completion(.failure(.userAlreadyExists))
                }
                return
            }
            
            // 验证邮箱格式
            if !self.isValidEmail(email) {
                DispatchQueue.main.async {
                    completion(.failure(.invalidEmail))
                }
                return
            }
            
            // 验证密码长度
            if password.count < 6 {
                DispatchQueue.main.async {
                    completion(.failure(.passwordTooShort))
                }
                return
            }
            
            // 创建新用户
            let newUser = MockUser(
                id: self.nextUserId,
                username: username,
                password: password,
                email: email,
                createdAt: Date()
            )
            
            self.mockUsers[username] = newUser
            self.nextUserId += 1
            
            // 生成 Token
            let accessToken = self.generateToken(userId: newUser.id, username: newUser.username, type: .access)
            let refreshToken = self.generateToken(userId: newUser.id, username: newUser.username, type: .refresh)
            
            // 保存 Token 到模拟服务端
            self.activeTokens[accessToken] = TokenInfo(
                userId: newUser.id,
                username: newUser.username,
                expiresAt: Date().addingTimeInterval(30 * 60), // 30分钟
                type: .access
            )
            
            self.activeTokens[refreshToken] = TokenInfo(
                userId: newUser.id,
                username: newUser.username,
                expiresAt: Date().addingTimeInterval(7 * 24 * 60 * 60), // 7天
                type: .refresh
            )
            
            // 返回响应
            let response = RegisterResponse(
                accessToken: accessToken,
                refreshToken: refreshToken,
                user: UserInfo(
                    id: newUser.id,
                    username: newUser.username,
                    email: newUser.email
                )
            )
            
            DispatchQueue.main.async {
                print("✅ Mock 注册成功: \(newUser.username)")
                completion(.success(response))
            }
        }
    }
    
    // MARK: - Token 验证
    
    /// 验证 Token
    /// - Parameter token: Token 字符串
    /// - Returns: Token 信息（如果有效）
    func validateToken(_ token: String) -> TokenInfo? {
        guard let tokenInfo = activeTokens[token] else {
            return nil
        }
        
        // 检查是否过期
        if tokenInfo.expiresAt < Date() {
            activeTokens.removeValue(forKey: token)
            return nil
        }
        
        return tokenInfo
    }
    
    /// 刷新 Token
    /// - Parameters:
    ///   - refreshToken: Refresh Token
    ///   - completion: 完成回调
    func refreshToken(_ refreshToken: String, completion: @escaping (Result<LoginResponse, AuthError>) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            // 验证 Refresh Token
            guard let tokenInfo = self.validateToken(refreshToken) else {
                DispatchQueue.main.async {
                    completion(.failure(.tokenExpired))
                }
                return
            }
            
            // 生成新的 Access Token
            let newAccessToken = self.generateToken(userId: tokenInfo.userId, username: tokenInfo.username, type: .access)
            
            self.activeTokens[newAccessToken] = TokenInfo(
                userId: tokenInfo.userId,
                username: tokenInfo.username,
                expiresAt: Date().addingTimeInterval(30 * 60),
                type: .access
            )
            
            // 查找用户信息
            guard let user = self.mockUsers.values.first(where: { $0.id == tokenInfo.userId }) else {
                DispatchQueue.main.async {
                    completion(.failure(.userNotFound))
                }
                return
            }
            
            let response = LoginResponse(
                accessToken: newAccessToken,
                refreshToken: refreshToken,
                user: UserInfo(
                    id: user.id,
                    username: user.username,
                    email: user.email
                )
            )
            
            DispatchQueue.main.async {
                print("✅ Token 刷新成功: \(tokenInfo.username)")
                completion(.success(response))
            }
        }
    }
    
    // MARK: - 私有方法
    
    /// 生成 Token
    private func generateToken(userId: Int, username: String, type: TokenType) -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let random = UUID().uuidString.prefix(8)
        return "\(type.rawValue)_\(userId)_\(timestamp)_\(random)"
    }
    
    /// 验证邮箱格式
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // MARK: - 调试方法
    
    /// 获取所有用户（仅用于调试）
    func getAllUsers() -> [MockUser] {
        return Array(mockUsers.values)
    }
    
    /// 清除所有 Token（仅用于调试）
    func clearAllTokens() {
        activeTokens.removeAll()
    }
}

