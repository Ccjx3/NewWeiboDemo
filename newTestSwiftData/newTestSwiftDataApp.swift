//
//  newTestSwiftDataApp.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/23.
//

import SwiftUI
import SwiftData

@main
struct newTestSwiftDataApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Post.self,  // 使用 Post 模型替代 Item
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // 如果创建失败，尝试删除旧数据库并重新创建
            print("⚠️ ModelContainer 创建失败: \(error)")
            print("🔄 尝试删除旧数据库并重新创建...")
                
            // 删除旧的数据库文件
            let url = modelConfiguration.url
            try? FileManager.default.removeItem(at: url)
            print("🗑️ 已删除旧数据库: \(url.path)")
            
            // 重新尝试创建
            do {
                let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                print("✅ ModelContainer 重新创建成功")
                return container
            } catch {
                fatalError("无法创建 ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
