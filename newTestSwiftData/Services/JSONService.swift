//
//  JSONService.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/23.
//

import Foundation
import SwiftData

/// JSON 数据服务
/// 负责从 JSON 文件加载数据到 SwiftData，以及将 SwiftData 数据保存回 JSON 文件
class JSONService {
    
    /// 从 JSON 文件加载数据到 SwiftData
    /// - Parameters:
    ///   - fileName: JSON 文件名（不包含路径）
    ///   - modelContext: SwiftData 的模型上下文
    /// - Returns: 加载的 Post 数组
    static func loadPostsFromJSON(fileName: String, modelContext: ModelContext) -> [Post] {
        // 尝试多种路径查找 JSON 文件
        var url: URL?
        
        // 方法1: 在 Resources 子目录中查找
        url = Bundle.main.url(forResource: fileName, withExtension: nil, subdirectory: "Resources")
        
        // 方法2: 直接在 Bundle 根目录查找
        if url == nil {
            url = Bundle.main.url(forResource: fileName, withExtension: nil)
        }
        
        // 方法3: 尝试去掉扩展名
        if url == nil {
            let nameWithoutExt = (fileName as NSString).deletingPathExtension
            url = Bundle.main.url(forResource: nameWithoutExt, withExtension: "json", subdirectory: "Resources")
        }
        
        guard let fileURL = url else {
            print("❌ 无法找到 JSON 文件: \(fileName)")
            print("   请确保文件已添加到 Xcode 项目的 Bundle 中")
            return []
        }
        
        print("📂 找到 JSON 文件: \(fileURL.path)")
        
        do {
            let data = try Data(contentsOf: fileURL)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("❌ JSON 解析失败：无法转换为字典")
                return []
            }
            
            guard let list = json["list"] as? [[String: Any]] else {
                print("❌ JSON 格式错误，缺少 'list' 字段")
                print("   JSON 结构: \(json.keys)")
                return []
            }
            
            print("📊 找到 \(list.count) 条帖子数据")
            
            var posts: [Post] = []
            var skippedCount = 0
            
            // 先创建所有 Post 对象，再批量插入
            var postsToInsert: [Post] = []
            
            for (index, item) in list.enumerated() {
                guard let post = Post(from: item) else {
                    print("⚠️ 跳过第 \(index + 1) 条数据：无法创建 Post 对象")
                    skippedCount += 1
                    continue
                }
                
                // 检查是否已存在相同 ID 的帖子
                let postId = post.id
                let descriptor = FetchDescriptor<Post>(
                    predicate: #Predicate<Post> { p in
                        p.id == postId
                    }
                )
                
                do {
                    let existingPosts = try modelContext.fetch(descriptor)
                    
                    if existingPosts.isEmpty {
                        postsToInsert.append(post)
                    } else {
                        print("⚠️ 跳过 ID \(postId) 的帖子：已存在")
                        skippedCount += 1
                    }
                } catch {
                    print("⚠️ 查询已存在帖子时出错: \(error.localizedDescription)")
                    // 即使查询失败，也尝试插入（可能数据库刚创建）
                    postsToInsert.append(post)
                }
            }
            
            // 批量插入所有新帖子
            for post in postsToInsert {
                modelContext.insert(post)
                posts.append(post)
            }
            
            do {
                try modelContext.save()
                print("✅ 成功加载 \(posts.count) 条帖子到 SwiftData")
                if skippedCount > 0 {
                    print("   (跳过了 \(skippedCount) 条重复或无效数据)")
                }
            } catch {
                print("❌ 保存到 SwiftData 失败: \(error.localizedDescription)")
            }
            
            return posts
            
        } catch {
            print("❌ 加载 JSON 失败: \(error.localizedDescription)")
            return []
        }
    }
    
    /// 将 SwiftData 中的所有 Post 保存到 JSON 文件
    /// - Parameters:
    ///   - fileName: JSON 文件名（不包含路径）
    ///   - modelContext: SwiftData 的模型上下文
    /// - Returns: 是否保存成功
    static func savePostsToJSON(fileName: String, modelContext: ModelContext) -> Bool {
        do {
            // 根据文件名确定 ID 范围
            let idRange: Range<Int>
            if fileName.contains("recommend") {
                idRange = 1000..<4000  // 包含普通帖子(1000-1999)和视频帖子(3000-3999)
            } else if fileName.contains("hot") {
                idRange = 2000..<3000
            } else {
                // 默认保存所有帖子
                let descriptor = FetchDescriptor<Post>(sortBy: [SortDescriptor(\.id)])
                let posts = try modelContext.fetch(descriptor)
                
                let jsonArray = posts.map { $0.toJSON() }
                let json: [String: Any] = ["list": jsonArray]
                
                guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                    print("❌ 无法获取 Documents 目录")
                    return false
                }
                
                let fileURL = documentsURL.appendingPathComponent(fileName)
                let jsonData = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
                try jsonData.write(to: fileURL)
                
                print("✅ 成功保存 \(posts.count) 条帖子到: \(fileURL.path)")
                return true
            }
            
            // 只获取指定 ID 范围的帖子
            let minId = idRange.lowerBound
            let maxId = idRange.upperBound
            let descriptor = FetchDescriptor<Post>(
                predicate: #Predicate<Post> { post in
                    post.id >= minId && post.id < maxId
                },
                sortBy: [SortDescriptor(\.id)]
            )
            let posts = try modelContext.fetch(descriptor)
            
            let jsonArray = posts.map { $0.toJSON() }
            let json: [String: Any] = ["list": jsonArray]
            
            // 获取 Documents 目录路径（可写）
            guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                print("❌ 无法获取 Documents 目录")
                return false
            }
            
            let fileURL = documentsURL.appendingPathComponent(fileName)
            
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
            try jsonData.write(to: fileURL)
            
            print("✅ 成功保存 \(posts.count) 条帖子（ID范围: \(idRange)）到: \(fileURL.path)")
            return true
            
        } catch {
            print("❌ 保存 JSON 失败: \(error.localizedDescription)")
            return false
        }
    }
    
    /// 将 SwiftData 中的所有 Post 保存到 Bundle 中的 JSON 文件（需要特殊处理，因为 Bundle 是只读的）
    /// 注意：Bundle 中的文件是只读的，所以这个方法会保存到 Documents 目录
    /// - Parameters:
    ///   - fileName: JSON 文件名（不包含路径）
    ///   - modelContext: SwiftData 的模型上下文
    /// - Returns: 是否保存成功
    static func savePostsToBundleJSON(fileName: String, modelContext: ModelContext) -> Bool {
        // Bundle 是只读的，所以保存到 Documents 目录
        // 在实际应用中，你可能需要手动将文件复制回项目
        return savePostsToJSON(fileName: fileName, modelContext: modelContext)
    }
}
