//
//  KeychainManager.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/30.
//

import Foundation
import KeychainSwift

/// Keychain 管理器 - 安全存储 Token
class KeychainManager {
    static let shared = KeychainManager()
    
    private let keychain: KeychainSwift
    
    private init() {
        keychain = KeychainSwift()
        keychain.synchronizable = false  // 不同步到 iCloud
        keychain.accessGroup = nil  // 不共享到其他 App
    }
    
    // MARK: - Refresh Token
    
    /// 保存 Refresh Token
    func saveRefreshToken(_ token: String) -> Bool {
        return keychain.set(token, forKey: "refreshToken")
    }
    
    /// 读取 Refresh Token
    func getRefreshToken() -> String? {
        return keychain.get("refreshToken")
    }
    
    /// 删除 Refresh Token
    func deleteRefreshToken() -> Bool {
        return keychain.delete("refreshToken")
    }
    
    // MARK: - Access Token
    
    /// 保存 Access Token
    func saveAccessToken(_ token: String) -> Bool {
        return keychain.set(token, forKey: "accessToken")
    }
    
    /// 读取 Access Token
    func getAccessToken() -> String? {
        return keychain.get("accessToken")
    }
    
    /// 删除 Access Token
    func deleteAccessToken() -> Bool {
        return keychain.delete("accessToken")
    }
    
    // MARK: - 清除所有
    
    /// 清除所有 Token
    func clearAll() -> Bool {
        return keychain.clear()
    }
}

