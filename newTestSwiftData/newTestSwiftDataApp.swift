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
    // Post 数据库（原有的）
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Post.self,  // 帖子模型
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
    
    init() {
        // 初始化 SwiftDataAuthService（使用独立的数据库）
        _ = SwiftDataAuthService.shared
        
        // 延迟打印，确保数据库初始化完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("\n🔍 查询认证数据库信息：")
            SwiftDataAuthService.shared.printAllUsers()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AuthManager.shared)  // 注入 AuthManager
        }
        .modelContainer(sharedModelContainer)  // 只注入 Post 数据库
    }
}
