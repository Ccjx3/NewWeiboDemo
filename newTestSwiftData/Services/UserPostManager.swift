//
//  UserPostManager.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/2/1.
//

import Foundation
import SwiftData

/// 用户帖子管理器
/// 负责管理用户创建的帖子，包括：
/// 1. 保存到本地 JSON 文件
/// 2. 加载用户帖子
/// 3. 删除用户帖子
class UserPostManager {
    static let shared = UserPostManager()
    
    private init() {}
    
    // MARK: - 配置
    
    /// 用户帖子 JSON 文件名
    private let userPostsFileName = "UserPosts.json"
    
    /// 用户帖子 ID 起始值
    private let userPostIDStart = 10000
    
    // MARK: - 文件路径
    
    /// 获取用户帖子文件路径
    private var userPostsFileURL: URL {
        let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        return documentsURL.appendingPathComponent(userPostsFileName)
    }
    
    // MARK: - 保存帖子
    
    /// 保存用户帖子到 JSON 文件
    /// - Parameters:
    ///   - post: 帖子对象
    ///   - modelContext: SwiftData 上下文
    /// - Returns: 是否保存成功
    @discardableResult
    func saveUserPost(_ post: Post, modelContext: ModelContext) -> Bool {
        // 1. 读取现有用户帖子
        var userPosts = loadUserPosts()
        
        // 2. 检查是否已存在（更新）
        if let index = userPosts.firstIndex(where: { $0.id == post.id }) {
            userPosts[index] = post
            print("📝 更新现有帖子: ID \(post.id)")
        } else {
            // 3. 添加新帖子
            userPosts.append(post)
            print("➕ 添加新帖子: ID \(post.id)")
        }
        
        // 4. 转换为 JSON
        let jsonArray = userPosts.map { $0.toJSON() }
        let json: [String: Any] = [
            "list": jsonArray,
            "source": "user_created",
            "version": "1.0",
            "lastModified": ISO8601DateFormatter().string(from: Date()),
            "totalCount": userPosts.count
        ]
        
        // 5. 写入文件
        do {
            let jsonData = try JSONSerialization.data(
                withJSONObject: json,
                options: [.prettyPrinted, .sortedKeys]
            )
            try jsonData.write(to: userPostsFileURL)
            print("✅ 用户帖子已保存到: \(userPostsFileURL.path)")
            print("   - 总数: \(userPosts.count) 条")
            return true
        } catch {
            print("❌ 保存用户帖子失败: \(error)")
            return false
        }
    }
    
    /// 批量保存用户帖子
    /// - Parameters:
    ///   - posts: 帖子数组
    ///   - modelContext: SwiftData 上下文
    /// - Returns: 是否保存成功
    @discardableResult
    func saveUserPosts(_ posts: [Post], modelContext: ModelContext) -> Bool {
        let jsonArray = posts.map { $0.toJSON() }
        let json: [String: Any] = [
            "list": jsonArray,
            "source": "user_created",
            "version": "1.0",
            "lastModified": ISO8601DateFormatter().string(from: Date()),
            "totalCount": posts.count
        ]
        
        do {
            let jsonData = try JSONSerialization.data(
                withJSONObject: json,
                options: [.prettyPrinted, .sortedKeys]
            )
            try jsonData.write(to: userPostsFileURL)
            print("✅ 批量保存 \(posts.count) 条用户帖子")
            return true
        } catch {
            print("❌ 批量保存失败: \(error)")
            return false
        }
    }
    
    // MARK: - 加载帖子
    
    /// 从 JSON 文件加载用户帖子
    /// - Returns: 帖子数组
    func loadUserPosts() -> [Post] {
        guard FileManager.default.fileExists(atPath: userPostsFileURL.path) else {
            print("ℹ️ 用户帖子文件不存在，返回空数组")
            return []
        }
        
        do {
            let data = try Data(contentsOf: userPostsFileURL)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let list = json?["list"] as? [[String: Any]] ?? []
            
            let posts = list.compactMap { Post(from: $0) }
            print("✅ 加载了 \(posts.count) 条用户帖子")
            return posts
            
        } catch {
            print("❌ 加载用户帖子失败: \(error)")
            return []
        }
    }
    
    /// 加载用户帖子到 SwiftData
    /// - Parameter modelContext: SwiftData 上下文
    func loadUserPostsToSwiftData(modelContext: ModelContext) {
        let userPosts = loadUserPosts()
        
        for post in userPosts {
            // 检查是否已存在
            let postId = post.id
            let descriptor = FetchDescriptor<Post>(
                predicate: #Predicate<Post> { p in
                    p.id == postId
                }
            )
            
            let existing = try? modelContext.fetch(descriptor)
            if existing?.isEmpty ?? true {
                modelContext.insert(post)
            }
        }
        
        do {
            try modelContext.save()
            print("✅ 用户帖子已加载到 SwiftData")
        } catch {
            print("❌ 保存到 SwiftData 失败: \(error)")
        }
    }
    
    // MARK: - 删除帖子
    
    /// 删除用户帖子
    /// - Parameters:
    ///   - postId: 帖子 ID
    ///   - modelContext: SwiftData 上下文
    /// - Returns: 是否删除成功
    @discardableResult
    func deleteUserPost(postId: Int, modelContext: ModelContext) -> Bool {
        // 1. 从 JSON 文件中删除
        var userPosts = loadUserPosts()
        
        guard let index = userPosts.firstIndex(where: { $0.id == postId }) else {
            print("⚠️ 未找到要删除的帖子: ID \(postId)")
            return false
        }
        
        let deletedPost = userPosts.remove(at: index)
        
        // 2. 删除关联的媒体文件
        MediaManager.shared.deleteMediaFiles(relativePaths: deletedPost.images)
        if !deletedPost.videoUrl.isEmpty {
            MediaManager.shared.deleteMedia(relativePath: deletedPost.videoUrl)
        }
        
        // 3. 保存更新后的 JSON
        let jsonArray = userPosts.map { $0.toJSON() }
        let json: [String: Any] = [
            "list": jsonArray,
            "source": "user_created",
            "version": "1.0",
            "lastModified": ISO8601DateFormatter().string(from: Date()),
            "totalCount": userPosts.count
        ]
        
        do {
            let jsonData = try JSONSerialization.data(
                withJSONObject: json,
                options: [.prettyPrinted, .sortedKeys]
            )
            try jsonData.write(to: userPostsFileURL)
            print("✅ 帖子已从 JSON 删除: ID \(postId)")
            return true
        } catch {
            print("❌ 删除帖子失败: \(error)")
            return false
        }
    }
    
    // MARK: - ID 生成
    
    /// 生成新的用户帖子 ID
    /// - Parameter modelContext: SwiftData 上下文
    /// - Returns: 新的帖子 ID
    func generateNewUserPostID(modelContext: ModelContext) -> Int {
        // 从 SwiftData 查询最大 ID
        let minId = userPostIDStart
        let descriptor = FetchDescriptor<Post>(
            predicate: #Predicate<Post> { post in
                post.id >= minId
            },
            sortBy: [SortDescriptor(\.id, order: .reverse)]
        )
        
        let existingPosts = try? modelContext.fetch(descriptor)
        let maxId = existingPosts?.first?.id ?? (userPostIDStart - 1)
        
        return maxId + 1
    }
    
    // MARK: - 工具方法
    
    /// 获取用户帖子总数
    /// - Returns: 帖子数量
    func getUserPostCount() -> Int {
        return loadUserPosts().count
    }
    
    /// 清空所有用户帖子
    /// - Returns: 是否清空成功
    @discardableResult
    func clearAllUserPosts() -> Bool {
        // 1. 删除所有媒体文件
        let userPosts = loadUserPosts()
        for post in userPosts {
            MediaManager.shared.deleteMediaFiles(relativePaths: post.images)
            if !post.videoUrl.isEmpty {
                MediaManager.shared.deleteMedia(relativePath: post.videoUrl)
            }
        }
        
        // 2. 删除 JSON 文件
        do {
            if FileManager.default.fileExists(atPath: userPostsFileURL.path) {
                try FileManager.default.removeItem(at: userPostsFileURL)
            }
            print("✅ 已清空所有用户帖子")
            return true
        } catch {
            print("❌ 清空用户帖子失败: \(error)")
            return false
        }
    }
    
    /// 导出用户帖子数据
    /// - Returns: JSON 字符串
    func exportUserPostsJSON() -> String? {
        guard FileManager.default.fileExists(atPath: userPostsFileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: userPostsFileURL)
            return String(data: data, encoding: .utf8)
        } catch {
            print("❌ 导出失败: \(error)")
            return nil
        }
    }
    
    /// 获取用户帖子文件大小
    /// - Returns: 文件大小（字节）
    func getUserPostsFileSize() -> Int64 {
        guard FileManager.default.fileExists(atPath: userPostsFileURL.path) else {
            return 0
        }
        
        let attributes = try? FileManager.default.attributesOfItem(atPath: userPostsFileURL.path)
        return attributes?[.size] as? Int64 ?? 0
    }
}

