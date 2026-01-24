//
//  PostListView.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/23.
//

import SwiftUI
import SwiftData

/// 帖子列表视图
/// 展示所有帖子，支持添加、删除、点赞等操作
struct PostListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Post.id, order: .forward) private var posts: [Post]
    
    @State private var showingAddPost = false
    @State private var hasLoadedInitialData = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("加载中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    if posts.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "tray")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("暂无帖子")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("点击右上角 + 添加新帖子")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(posts) { post in
                                PostCellView(post: post)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                                    .listRowSeparator(.hidden)
                            }
                            .onDelete(perform: deletePosts)
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("帖子列表")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddPost = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingAddPost) {
                AddPostView()
            }
            .task {
                // 使用 task 确保在主线程执行，并且只在首次加载时执行
                await loadInitialDataIfNeeded()
            }
        }
    }
    
    /// 如果需要，从 JSON 加载初始数据
    @MainActor
    private func loadInitialDataIfNeeded() async {
        // 避免重复加载
        guard !hasLoadedInitialData else {
            return
        }
        
        // 设置标志，防止重复加载
        hasLoadedInitialData = true
        
        // 确保 modelContext 可用
        guard modelContext.container != nil else {
            print("❌ ModelContext 不可用")
            hasLoadedInitialData = false
            return
        }
        
        // 检查数据库中是否已有数据
        do {
            let descriptor = FetchDescriptor<Post>()
            let existingPosts = try modelContext.fetch(descriptor)
            
            // 如果数据库不为空，直接返回
            if !existingPosts.isEmpty {
                print("✅ 数据库已有 \(existingPosts.count) 条帖子，无需加载")
                return
            }
            
            // 如果数据库为空，从 JSON 加载初始数据
            print("📥 开始从 JSON 加载初始数据...")
            isLoading = true
            
            // 在主线程上执行加载
            let loadedPosts = JSONService.loadPostsFromJSON(
                fileName: "PostListData_recommend_1.json",
                modelContext: modelContext
            )
            
            isLoading = false
            
            if loadedPosts.isEmpty {
                print("⚠️ 未能加载任何帖子数据")
            } else {
                print("✅ 成功加载 \(loadedPosts.count) 条帖子")
            }
            
        } catch {
            isLoading = false
            hasLoadedInitialData = false
            print("❌ 检查数据库时出错: \(error.localizedDescription)")
        }
    }
    
    /// 删除帖子
    private func deletePosts(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(posts[index])
            }
            // 删除后同步到 JSON
            JSONService.savePostsToJSON(fileName: "PostListData_recommend_1.json", modelContext: modelContext)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Post.self, configurations: config)
    
    return PostListView()
        .modelContainer(container)
}
