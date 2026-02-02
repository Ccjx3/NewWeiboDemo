//
//  MockPostAPIService.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/2/1.
//

import Foundation

/// Mock API 响应结果
enum MockAPIResult<T> {
    case success(T)
    case failure(MockAPIError)
}

/// Mock API 错误
struct MockAPIError: Error {
    let code: Int
    let message: String
    
    static let unauthorized = MockAPIError(code: 401, message: "未授权，请先登录")
    static let tokenExpired = MockAPIError(code: 401, message: "Token 已过期")
    static let invalidToken = MockAPIError(code: 401, message: "无效的 Token")
    static let networkError = MockAPIError(code: 500, message: "网络错误")
    static let serverError = MockAPIError(code: 500, message: "服务器错误")
    static let invalidData = MockAPIError(code: 400, message: "数据格式错误")
}

/// 发帖请求数据
struct CreatePostRequest {
    let text: String
    let images: [String]  // 本地相对路径
    let videoUrl: String  // 本地相对路径
}

/// 发帖响应数据
struct CreatePostResponse {
    let success: Bool
    let message: String
    let postId: Int
    let createdAt: String
}

/// Mock 发帖 API 服务
/// 模拟真实的网络请求流程，包括：
/// 1. Token 验证
/// 2. 网络延迟模拟
/// 3. 随机失败模拟（可选）
/// 4. 数据验证
class MockPostAPIService {
    static let shared = MockPostAPIService()
    
    private init() {}
    
    // MARK: - 配置项
    
    /// 是否启用随机失败（用于测试）
    var enableRandomFailure = false
    
    /// 随机失败概率（0.0 - 1.0）
    var failureRate: Double = 0.1
    
    /// 模拟网络延迟（秒）
    var networkDelay: TimeInterval = 1.5
    
    // MARK: - 发帖 API
    
    /// 创建帖子（模拟网络请求）
    /// - Parameters:
    ///   - request: 发帖请求数据
    ///   - accessToken: 访问令牌
    ///   - completion: 完成回调
    func createPost(
        request: CreatePostRequest,
        accessToken: String?,
        completion: @escaping (MockAPIResult<CreatePostResponse>) -> Void
    ) {
        print("📡 [Mock API] 开始发送帖子请求...")
        print("   - 文字内容: \(request.text.prefix(20))...")
        print("   - 图片数量: \(request.images.count)")
        print("   - 视频: \(request.videoUrl.isEmpty ? "无" : "有")")
        print("   - Access Token: \(accessToken?.prefix(20) ?? "nil")...")
        
        // 模拟网络延迟
        DispatchQueue.global().asyncAfter(deadline: .now() + networkDelay) { [weak self] in
            guard let self = self else { return }
            
            // 1. 验证 Token
            guard let token = accessToken, !token.isEmpty else {
                print("❌ [Mock API] Token 验证失败: 未提供 Token")
                DispatchQueue.main.async {
                    completion(.failure(.unauthorized))
                }
                return
            }
            
            // 2. 验证 Token 有效性（通过 KeychainManager）
            let storedToken = KeychainManager.shared.getAccessToken()
            if token != storedToken {
                print("❌ [Mock API] Token 验证失败: Token 不匹配")
                DispatchQueue.main.async {
                    completion(.failure(.invalidToken))
                }
                return
            }
            
            // 3. 验证 Token 是否过期（通过 SwiftDataAuthService）
            if !SwiftDataAuthService.shared.isTokenValid(token) {
                print("❌ [Mock API] Token 验证失败: Token 已过期")
                DispatchQueue.main.async {
                    completion(.failure(.tokenExpired))
                }
                return
            }
            
            print("✅ [Mock API] Token 验证通过")
            
            // 4. 模拟随机失败（用于测试）
            if self.enableRandomFailure && Double.random(in: 0...1) < self.failureRate {
                print("⚠️ [Mock API] 模拟网络错误")
                DispatchQueue.main.async {
                    completion(.failure(.networkError))
                }
                return
            }
            
            // 5. 验证数据
            if request.text.isEmpty {
                print("❌ [Mock API] 数据验证失败: 文字内容为空")
                DispatchQueue.main.async {
                    completion(.failure(.invalidData))
                }
                return
            }
            
            // 6. 模拟服务器处理（生成帖子 ID）
            let postId = self.generatePostId()
            
            // 7. 生成响应
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            let createdAt = dateFormatter.string(from: Date())
            
            let response = CreatePostResponse(
                success: true,
                message: "发布成功",
                postId: postId,
                createdAt: createdAt
            )
            
            print("✅ [Mock API] 帖子发布成功")
            print("   - 帖子 ID: \(postId)")
            print("   - 创建时间: \(createdAt)")
            
            DispatchQueue.main.async {
                completion(.success(response))
            }
        }
    }
    
    // MARK: - 辅助方法
    
    /// 生成帖子 ID（用户帖子从 10000 开始）
    private func generatePostId() -> Int {
        // 从 UserDefaults 读取上次的 ID
        let lastId = UserDefaults.standard.integer(forKey: "lastUserPostId")
        let newId = lastId == 0 ? 10000 : lastId + 1
        
        // 保存新 ID
        UserDefaults.standard.set(newId, forKey: "lastUserPostId")
        
        return newId
    }
    
    /// 重置帖子 ID 计数器
    func resetPostIdCounter() {
        UserDefaults.standard.removeObject(forKey: "lastUserPostId")
        print("✅ 帖子 ID 计数器已重置")
    }
    
    // MARK: - 模拟其他 API
    
    /// 删除帖子（模拟）
    /// - Parameters:
    ///   - postId: 帖子 ID
    ///   - accessToken: 访问令牌
    ///   - completion: 完成回调
    func deletePost(
        postId: Int,
        accessToken: String?,
        completion: @escaping (MockAPIResult<Bool>) -> Void
    ) {
        print("📡 [Mock API] 删除帖子请求: ID \(postId)")
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            // 验证 Token
            guard let token = accessToken,
                  !token.isEmpty,
                  SwiftDataAuthService.shared.isTokenValid(token) else {
                DispatchQueue.main.async {
                    completion(.failure(.unauthorized))
                }
                return
            }
            
            // 只能删除用户自己的帖子（ID >= 10000）
            guard postId >= 10000 else {
                DispatchQueue.main.async {
                    completion(.failure(MockAPIError(code: 403, message: "无权删除此帖子")))
                }
                return
            }
            
            print("✅ [Mock API] 帖子删除成功")
            DispatchQueue.main.async {
                completion(.success(true))
            }
        }
    }
    
    /// 更新帖子（模拟）
    /// - Parameters:
    ///   - postId: 帖子 ID
    ///   - text: 新的文字内容
    ///   - accessToken: 访问令牌
    ///   - completion: 完成回调
    func updatePost(
        postId: Int,
        text: String,
        accessToken: String?,
        completion: @escaping (MockAPIResult<Bool>) -> Void
    ) {
        print("📡 [Mock API] 更新帖子请求: ID \(postId)")
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.8) {
            // 验证 Token
            guard let token = accessToken,
                  !token.isEmpty,
                  SwiftDataAuthService.shared.isTokenValid(token) else {
                DispatchQueue.main.async {
                    completion(.failure(.unauthorized))
                }
                return
            }
            
            // 只能更新用户自己的帖子
            guard postId >= 10000 else {
                DispatchQueue.main.async {
                    completion(.failure(MockAPIError(code: 403, message: "无权修改此帖子")))
                }
                return
            }
            
            print("✅ [Mock API] 帖子更新成功")
            DispatchQueue.main.async {
                completion(.success(true))
            }
        }
    }
}

// MARK: - 扩展：SwiftDataAuthService Token 验证

extension SwiftDataAuthService {
    /// 验证 Token 是否有效（不过期）
    /// - Parameter tokenString: Token 字符串
    /// - Returns: 是否有效
    func isTokenValid(_ tokenString: String) -> Bool {
        guard let tokenInfo = validateToken(tokenString) else {
            return false
        }
        
        // 检查是否过期
        return tokenInfo.expiresAt > Date()
    }
}

