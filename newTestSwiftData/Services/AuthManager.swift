//
//  AuthManager.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/29.
//

import SwiftUI
import Combine

/// 认证管理器 - 管理用户登录状态
class AuthManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var username: String = ""
    @Published var userId: Int = 0
    @Published var email: String = ""
    
    // Access Token 存储在内存中（短期有效）
    private(set) var accessToken: String?
    
    static let shared = AuthManager()
    
    private init() {
        checkLoginState()
    }
    
    // MARK: - 检查登录状态
    
    /// App 启动时检查登录状态（自动登录）
    private func checkLoginState() {
        // 从 Keychain 读取 Refresh Token
        if let refreshToken = KeychainManager.shared.getRefreshToken() {
            // 验证 Token 是否有效（使用 SwiftDataAuthService）
            if let tokenInfo = SwiftDataAuthService.shared.validateToken(refreshToken) {
                // Token 有效，自动登录
                self.username = tokenInfo.username
                self.userId = tokenInfo.userId
                self.isLoggedIn = true
                
                // 从 UserDefaults 读取邮箱
                self.email = UserDefaults.standard.string(forKey: "userEmail") ?? ""
                
                // 尝试读取 Access Token
                self.accessToken = KeychainManager.shared.getAccessToken()
                
                print("✅ 自动登录成功: \(tokenInfo.username)")
            } else {
                // Token 已过期，清除
                print("⚠️ Refresh Token 已过期，需要重新登录")
                clearLoginData()
            }
        } else {
            print("ℹ️ 未登录")
        }
    }
    
    // MARK: - 登录
    
    /// 登录成功后保存信息
    /// - Parameters:
    ///   - response: 登录响应
    func login(response: LoginResponse) {
        self.username = response.user.username
        self.userId = response.user.id
        self.email = response.user.email
        self.isLoggedIn = true
        self.accessToken = response.accessToken
        
        // 保存 Refresh Token 到 Keychain（持久化、加密）
        let refreshSaved = KeychainManager.shared.saveRefreshToken(response.refreshToken)
        
        // 保存 Access Token 到 Keychain（可选，也可以只存内存）
        let accessSaved = KeychainManager.shared.saveAccessToken(response.accessToken)
        
        // 保存用户名和邮箱到 UserDefaults（方便显示）
        UserDefaults.standard.set(response.user.username, forKey: "username")
        UserDefaults.standard.set(response.user.email, forKey: "userEmail")
        UserDefaults.standard.set(response.user.id, forKey: "userId")
        
        print("✅ 登录信息已保存")
        print("   - Refresh Token: \(refreshSaved ? "✓" : "✗")")
        print("   - Access Token: \(accessSaved ? "✓" : "✗")")
        print("   - 用户名: \(response.user.username)")
    }
    
    // MARK: - 注册
    
    /// 注册成功后保存信息
    /// - Parameters:
    ///   - response: 注册响应
    func register(response: RegisterResponse) {
        self.username = response.user.username
        self.userId = response.user.id
        self.email = response.user.email
        self.isLoggedIn = true
        self.accessToken = response.accessToken
        
        // 保存 Token 到 Keychain
        KeychainManager.shared.saveRefreshToken(response.refreshToken)
        KeychainManager.shared.saveAccessToken(response.accessToken)
        
        // 保存用户信息到 UserDefaults
        UserDefaults.standard.set(response.user.username, forKey: "username")
        UserDefaults.standard.set(response.user.email, forKey: "userEmail")
        UserDefaults.standard.set(response.user.id, forKey: "userId")
        
        print("✅ 注册信息已保存: \(response.user.username)")
    }
    
    // MARK: - 退出登录
    
    /// 退出登录
    func logout() {
        // 清除内存中的数据
        self.username = ""
        self.userId = 0
        self.email = ""
        self.isLoggedIn = false
        self.accessToken = nil
        
        // 清除 Keychain 中的 Token
        clearLoginData()
        
        print("✅ 已退出登录")
    }
    
    // MARK: - 私有方法
    
    /// 清除登录数据
    private func clearLoginData() {
        // 清除 Keychain
        KeychainManager.shared.clearAll()
        
        // 清除 UserDefaults
        UserDefaults.standard.removeObject(forKey: "username")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "userId")
    }
    
    // MARK: - Token 刷新
    
    /// 刷新 Access Token
    /// - Parameter completion: 完成回调
    func refreshAccessToken(completion: @escaping (Bool) -> Void) {
        guard let refreshToken = KeychainManager.shared.getRefreshToken() else {
            print("❌ 没有 Refresh Token")
            completion(false)
            return
        }
        
        SwiftDataAuthService.shared.refreshToken(refreshToken) { [weak self] result in
            switch result {
            case .success(let response):
                self?.accessToken = response.accessToken
                KeychainManager.shared.saveAccessToken(response.accessToken)
                print("✅ Access Token 已刷新")
                completion(true)
                
            case .failure(let error):
                print("❌ Token 刷新失败: \(error.message)")
                self?.logout()
                completion(false)
            }
        }
    }
}

