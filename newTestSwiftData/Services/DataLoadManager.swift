//
//  DataLoadManager.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/2/1.
//

import Foundation
import SwiftData

/// 数据加载管理器
/// 负责统一管理网络数据和本地用户数据的加载
class DataLoadManager {
    static let shared = DataLoadManager()
    
    private init() {}
    
    // MARK: - 初始化数据
    
    /// 初始化所有数据（网络数据 + 用户本地数据）
    /// - Parameter modelContext: SwiftData 上下文
    func initializeData(modelContext: ModelContext) {
        print("\n📦 开始初始化数据...")
        
        // 1. 加载网络数据（Bundle 中的 JSON）
        loadNetworkData(modelContext: modelContext)
        
        // 2. 加载用户本地数据（Documents 中的 JSON）
        loadUserLocalData(modelContext: modelContext)
        
        print("✅ 数据初始化完成\n")
    }
    
    // MARK: - 加载网络数据
    
    /// 加载网络数据（从 Bundle 中的 JSON 文件）
    /// - Parameter modelContext: SwiftData 上下文
    private func loadNetworkData(modelContext: ModelContext) {
        print("📡 加载网络数据...")
        
        let networkFiles = [
            "PostListData_recommend_1.json",
            "PostListData_hot_1.json"
        ]
        
        var totalLoaded = 0
        
        for fileName in networkFiles {
            let posts = JSONService.loadPostsFromJSON(
                fileName: fileName,
                modelContext: modelContext
            )
            totalLoaded += posts.count
        }
        
        print("✅ 网络数据加载完成，共 \(totalLoaded) 条")
    }
    
    // MARK: - 加载用户本地数据
    
    /// 加载用户本地数据（从 Documents 中的 JSON 文件）
    /// - Parameter modelContext: SwiftData 上下文
    private func loadUserLocalData(modelContext: ModelContext) {
        print("💾 加载用户本地数据...")
        
        let userPosts = UserPostManager.shared.loadUserPosts()
        
        if userPosts.isEmpty {
            print("ℹ️ 没有用户本地数据")
            return
        }
        
        var insertedCount = 0
        
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
                insertedCount += 1
            }
        }
        
        do {
            try modelContext.save()
            print("✅ 用户本地数据加载完成，共 \(insertedCount) 条新数据")
        } catch {
            print("❌ 保存用户数据失败: \(error)")
        }
    }
    
    // MARK: - 数据统计
    
    /// 获取数据统计信息
    /// - Parameter modelContext: SwiftData 上下文
    /// - Returns: 统计信息字典
    func getDataStatistics(modelContext: ModelContext) -> [String: Int] {
        var stats: [String: Int] = [:]
        
        // 推荐数据 (1000-1999)
        let recommendDescriptor = FetchDescriptor<Post>(
            predicate: #Predicate<Post> { post in
                post.id >= 1000 && post.id < 2000
            }
        )
        stats["推荐"] = (try? modelContext.fetch(recommendDescriptor))?.count ?? 0
        
        // 热门数据 (2000-2999)
        let hotDescriptor = FetchDescriptor<Post>(
            predicate: #Predicate<Post> { post in
                post.id >= 2000 && post.id < 3000
            }
        )
        stats["热门"] = (try? modelContext.fetch(hotDescriptor))?.count ?? 0
        
        // 视频数据 (3000-3999)
        let videoDescriptor = FetchDescriptor<Post>(
            predicate: #Predicate<Post> { post in
                post.id >= 3000 && post.id < 4000
            }
        )
        stats["视频"] = (try? modelContext.fetch(videoDescriptor))?.count ?? 0
        
        // 用户本地数据 (10000+)
        let userDescriptor = FetchDescriptor<Post>(
            predicate: #Predicate<Post> { post in
                post.id >= 10000
            }
        )
        stats["本地"] = (try? modelContext.fetch(userDescriptor))?.count ?? 0
        
        return stats
    }
    
    /// 打印数据统计信息
    /// - Parameter modelContext: SwiftData 上下文
    func printDataStatistics(modelContext: ModelContext) {
        let stats = getDataStatistics(modelContext: modelContext)
        
        print("\n📊 数据统计：")
        print("   - 推荐: \(stats["推荐"] ?? 0) 条")
        print("   - 热门: \(stats["热门"] ?? 0) 条")
        print("   - 视频: \(stats["视频"] ?? 0) 条")
        print("   - 本地: \(stats["本地"] ?? 0) 条")
        print("   - 总计: \(stats.values.reduce(0, +)) 条\n")
    }
}

