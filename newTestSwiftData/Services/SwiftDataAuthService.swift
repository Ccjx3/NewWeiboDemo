//
//  SwiftDataAuthService.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/30.
//

import Foundation
import SwiftData

/// SwiftData 认证服务 - 使用真实数据库存储
class SwiftDataAuthService {
    static let shared = SwiftDataAuthService()
    
    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!
    
    private init() {
        setupModelContainer()
    }
    
    // MARK: - 初始化
    
    /// 设置 ModelContainer
    private func setupModelContainer() {
        // 为认证系统创建独立的 Schema 和数据库
        let schema = Schema([User.self, Token.self])
        
        // 使用独立的数据库文件名，避免与 Post 数据库冲突
        let authDatabaseURL = URL.documentsDirectory.appending(path: "AuthDatabase.store")
        let modelConfiguration = ModelConfiguration(
            url: authDatabaseURL  // 独立的数据库文件路径
        )
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContext = ModelContext(modelContainer)
            
            // 打印数据库位置
            printDatabaseLocation()
            
            // 初始化预置账号
            initializeDefaultUsers()
            
            // 清理过期 Token
            cleanExpiredTokens()
            
        } catch {
            fatalError("❌ 无法初始化 ModelContainer: \(error)")
        }
    }
    
    /// 打印数据库位置
    private func printDatabaseLocation() {
        if let url = modelContainer.configurations.first?.url {
            print("📁 SwiftData 数据库位置: \(url.path)")
        }
    }
    
    /// 初始化预置账号
    private func initializeDefaultUsers() {
        do {
            let descriptor = FetchDescriptor<User>()
            let existingUsers = try modelContext.fetch(descriptor)
            
            if existingUsers.isEmpty {
                // 创建预置账号
                let admin = User(
                    id: 1,
                    username: "admin",
                    password: "123456",
                    email: "admin@example.com",
                    isPreset: true
                )
                
                let test = User(
                    id: 2,
                    username: "test",
                    password: "123456",
                    email: "test@example.com",
                    isPreset: true
                )
                
                modelContext.insert(admin)
                modelContext.insert(test)
                
                try modelContext.save()
                print("✅ 预置账号已创建: admin, test")
            } else {
                print("ℹ️ 数据库已存在 \(existingUsers.count) 个用户")
            }
        } catch {
            print("❌ 初始化预置账号失败: \(error)")
        }
    }
    
    // MARK: - 登录
    
    /// 登录
    func login(username: String, password: String, completion: @escaping (Result<LoginResponse, AuthError>) -> Void) {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            
            // 模拟网络延迟
            Thread.sleep(forTimeInterval: 0.8)
            
            do {
                // 查询用户
                let predicate = #Predicate<User> { user in
                    user.username == username
                }
                var descriptor = FetchDescriptor<User>(predicate: predicate)
                descriptor.fetchLimit = 1
                
                guard let user = try self.modelContext.fetch(descriptor).first else {
                    DispatchQueue.main.async {
                        completion(.failure(.userNotFound))
                    }
                    return
                }
                
                // 验证密码
                guard user.validatePassword(password) else {
                    DispatchQueue.main.async {
                        completion(.failure(.invalidPassword))
                    }
                    return
                }
                
                // 生成 Token
                let accessToken = self.generateToken(userId: user.id, username: user.username, type: .access)
                let refreshToken = self.generateToken(userId: user.id, username: user.username, type: .refresh)
                
                // 保存 Token 到数据库
                let accessTokenModel = Token(
                    tokenString: accessToken,
                    type: .access,
                    expiresAt: Date().addingTimeInterval(30 * 60), // 30分钟
                    user: user
                )
                
                let refreshTokenModel = Token(
                    tokenString: refreshToken,
                    type: .refresh,
                    expiresAt: Date().addingTimeInterval(7 * 24 * 60 * 60), // 7天
                    user: user
                )
                
                self.modelContext.insert(accessTokenModel)
                self.modelContext.insert(refreshTokenModel)
                
                // 更新最后登录时间
                user.updateLastLogin()
                
                try self.modelContext.save()
                
                // 返回响应
                let response = LoginResponse(
                    accessToken: accessToken,
                    refreshToken: refreshToken,
                    user: user.toUserInfo()
                )
                
                DispatchQueue.main.async {
                    print("✅ SwiftData 登录成功: \(user.username)")
                    completion(.success(response))
                }
                
            } catch {
                DispatchQueue.main.async {
                    print("❌ 登录失败: \(error)")
                    completion(.failure(.networkError))
                }
            }
        }
    }
    
    // MARK: - 注册
    
    /// 注册
    func register(username: String, password: String, email: String, completion: @escaping (Result<RegisterResponse, AuthError>) -> Void) {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            
            // 模拟网络延迟
            Thread.sleep(forTimeInterval: 0.8)
            
            do {
                // 检查用户名是否存在
                let predicate = #Predicate<User> { user in
                    user.username == username
                }
                let descriptor = FetchDescriptor<User>(predicate: predicate)
                
                if let _ = try self.modelContext.fetch(descriptor).first {
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
                
                // 获取下一个 ID
                let allUsersDescriptor = FetchDescriptor<User>()
                let allUsers = try self.modelContext.fetch(allUsersDescriptor)
                let nextId = (allUsers.map { $0.id }.max() ?? 0) + 1
                
                // 创建新用户
                let newUser = User(
                    id: nextId,
                    username: username,
                    password: password,
                    email: email,
                    isPreset: false
                )
                
                self.modelContext.insert(newUser)
                
                // 生成 Token
                let accessToken = self.generateToken(userId: newUser.id, username: newUser.username, type: .access)
                let refreshToken = self.generateToken(userId: newUser.id, username: newUser.username, type: .refresh)
                
                // 保存 Token
                let accessTokenModel = Token(
                    tokenString: accessToken,
                    type: .access,
                    expiresAt: Date().addingTimeInterval(30 * 60),
                    user: newUser
                )
                
                let refreshTokenModel = Token(
                    tokenString: refreshToken,
                    type: .refresh,
                    expiresAt: Date().addingTimeInterval(7 * 24 * 60 * 60),
                    user: newUser
                )
                
                self.modelContext.insert(accessTokenModel)
                self.modelContext.insert(refreshTokenModel)
                
                try self.modelContext.save()
                
                // 返回响应
                let response = RegisterResponse(
                    accessToken: accessToken,
                    refreshToken: refreshToken,
                    user: newUser.toUserInfo()
                )
                
                DispatchQueue.main.async {
                    print("✅ SwiftData 注册成功: \(newUser.username)")
                    completion(.success(response))
                }
                
            } catch {
                DispatchQueue.main.async {
                    print("❌ 注册失败: \(error)")
                    completion(.failure(.networkError))
                }
            }
        }
    }
    
    // MARK: - Token 验证
    
    /// 验证 Token
    func validateToken(_ tokenString: String) -> TokenInfo? {
        do {
            let predicate = #Predicate<Token> { token in
                token.tokenString == tokenString
            }
            var descriptor = FetchDescriptor<Token>(predicate: predicate)
            descriptor.fetchLimit = 1
            
            guard let token = try modelContext.fetch(descriptor).first else {
                return nil
            }
            
            // 检查是否过期
            if token.isExpired {
                modelContext.delete(token)
                try? modelContext.save()
                return nil
            }
            
            return token.toTokenInfo()
            
        } catch {
            print("❌ 验证 Token 失败: \(error)")
            return nil
        }
    }
    
    /// 刷新 Token
    func refreshToken(_ refreshTokenString: String, completion: @escaping (Result<LoginResponse, AuthError>) -> Void) {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            
            Thread.sleep(forTimeInterval: 0.5)
            
            do {
                // 查找 Refresh Token
                let predicate = #Predicate<Token> { token in
                    token.tokenString == refreshTokenString && token.type == "refresh"
                }
                var descriptor = FetchDescriptor<Token>(predicate: predicate)
                descriptor.fetchLimit = 1
                
                guard let refreshToken = try self.modelContext.fetch(descriptor).first else {
                    DispatchQueue.main.async {
                        completion(.failure(.invalidToken))
                    }
                    return
                }
                
                // 检查是否过期
                if refreshToken.isExpired {
                    self.modelContext.delete(refreshToken)
                    try self.modelContext.save()
                    DispatchQueue.main.async {
                        completion(.failure(.tokenExpired))
                    }
                    return
                }
                
                guard let user = refreshToken.user else {
                    DispatchQueue.main.async {
                        completion(.failure(.userNotFound))
                    }
                    return
                }
                
                // 生成新的 Access Token
                let newAccessToken = self.generateToken(userId: user.id, username: user.username, type: .access)
                
                let accessTokenModel = Token(
                    tokenString: newAccessToken,
                    type: .access,
                    expiresAt: Date().addingTimeInterval(30 * 60),
                    user: user
                )
                
                self.modelContext.insert(accessTokenModel)
                try self.modelContext.save()
                
                let response = LoginResponse(
                    accessToken: newAccessToken,
                    refreshToken: refreshTokenString,
                    user: user.toUserInfo()
                )
                
                DispatchQueue.main.async {
                    print("✅ Token 刷新成功: \(user.username)")
                    completion(.success(response))
                }
                
            } catch {
                DispatchQueue.main.async {
                    print("❌ Token 刷新失败: \(error)")
                    completion(.failure(.networkError))
                }
            }
        }
    }
    
    // MARK: - 查询方法
    
    /// 获取所有用户（调试用）
    func getAllUsers() -> [User] {
        do {
            let descriptor = FetchDescriptor<User>(sortBy: [SortDescriptor(\.id)])
            return try modelContext.fetch(descriptor)
        } catch {
            print("❌ 获取用户列表失败: \(error)")
            return []
        }
    }
    
    /// 打印所有用户到控制台
    func printAllUsers() {
        let users = getAllUsers()
        print("\n========================================")
        print("📊 SwiftData 数据库用户列表")
        print("========================================")
        for (index, user) in users.enumerated() {
            print("[\(index + 1)] 用户名: \(user.username)")
            print("    密码: \(user.password)")
            print("    邮箱: \(user.email)")
            print("    ID: \(user.id)")
            print("    预置账号: \(user.isPreset ? "是" : "否")")
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            print("    创建时间: \(formatter.string(from: user.createdAt))")
            if let lastLogin = user.lastLoginAt {
                print("    最后登录: \(formatter.string(from: lastLogin))")
            }
            print("----------------------------------------")
        }
        print("总共 \(users.count) 个用户")
        print("========================================\n")
    }
    
    /// 获取所有 Token（调试用）
    func getAllTokens() -> [Token] {
        do {
            let descriptor = FetchDescriptor<Token>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
            return try modelContext.fetch(descriptor)
        } catch {
            print("❌ 获取 Token 列表失败: \(error)")
            return []
        }
    }
    
    /// 清理过期 Token
    func cleanExpiredTokens() {
        do {
            // 先获取当前时间，避免在 Predicate 中使用全局函数
            let now = Date()
            let predicate = #Predicate<Token> { token in
                token.expiresAt < now
            }
            let descriptor = FetchDescriptor<Token>(predicate: predicate)
            let expiredTokens = try modelContext.fetch(descriptor)
            
            for token in expiredTokens {
                modelContext.delete(token)
            }
            
            if !expiredTokens.isEmpty {
                try modelContext.save()
                print("🗑️ 已清理 \(expiredTokens.count) 个过期 Token")
            }
        } catch {
            print("❌ 清理过期 Token 失败: \(error)")
        }
    }
    
    /// 清除所有 Token（调试用）
    func clearAllTokens() {
        do {
            let descriptor = FetchDescriptor<Token>()
            let allTokens = try modelContext.fetch(descriptor)
            
            for token in allTokens {
                modelContext.delete(token)
            }
            
            try modelContext.save()
            print("🗑️ 已清除所有 Token")
        } catch {
            print("❌ 清除 Token 失败: \(error)")
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
}

