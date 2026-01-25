//
//  HomeView.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/25.
//

import SwiftUI
import SwiftData

/// 主页视图 - 支持推荐和热门内容切换
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    
    // 推荐和热门的帖子数据
    @Query(
        filter: #Predicate<Post> { post in
            post.id >= 1000 && post.id < 2000
        },
        sort: \Post.id,
        order: .forward
    ) private var recommendPosts: [Post]
    
    @Query(
        filter: #Predicate<Post> { post in
            post.id >= 2000 && post.id < 3000
        },
        sort: \Post.id,
        order: .forward
    ) private var hotPosts: [Post]
    
    @State private var leftPercent: CGFloat = 0 // 0 为推荐，1 为热门
    @State private var hasLoadedRecommend = false
    @State private var hasLoadedHot = false
    @State private var isLoading = false
    @State private var showingAddPost = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 自定义导航栏
                HomeNavigationBar(
                    leftPercent: $leftPercent,
                    onAddPost: {
                        showingAddPost = true
                    }
                )
                .padding(.top, 8)
                .background(Color(.systemBackground))
                
                Divider()
                
                // 内容区域 - 使用 TabView 实现滑动切换
                TabView(selection: $leftPercent) {
                    // 推荐页面
                    PostContentView(
                        posts: recommendPosts,
                        isLoading: isLoading,
                        emptyMessage: "暂无推荐内容"
                    )
                    .tag(CGFloat(0))
                    
                    // 热门页面
                    PostContentView(
                        posts: hotPosts,
                        isLoading: isLoading,
                        emptyMessage: "暂无热门内容"
                    )
                    .tag(CGFloat(1))
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddPost) {
                // 根据当前选中的标签页传递列表类型
                AddPostView(listType: leftPercent == 0 ? .recommend : .hot)
            }
            .task {
                await loadInitialData()
            }
        }
    }
    
    /// 加载初始数据
    @MainActor
    private func loadInitialData() async {
        // 避免重复加载
        guard !hasLoadedRecommend || !hasLoadedHot else {
            return
        }
        
        // 确保 modelContext 可用
        guard modelContext.container != nil else {
            print("❌ ModelContext 不可用")
            return
        }
        
        isLoading = true
        
        // 加载推荐数据
        if !hasLoadedRecommend && recommendPosts.isEmpty {
            print("📥 开始加载推荐数据...")
            let loaded = JSONService.loadPostsFromJSON(
                fileName: "PostListData_recommend_1.json",
                modelContext: modelContext
            )
            hasLoadedRecommend = true
            print("✅ 推荐数据加载完成: \(loaded.count) 条")
        }
        
        // 加载热门数据
        if !hasLoadedHot && hotPosts.isEmpty {
            print("📥 开始加载热门数据...")
            let loaded = JSONService.loadPostsFromJSON(
                fileName: "PostListData_hot_1.json",
                modelContext: modelContext
            )
            hasLoadedHot = true
            print("✅ 热门数据加载完成: \(loaded.count) 条")
        }
        
        isLoading = false
    }
}

/// 帖子内容视图 - 显示帖子列表
struct PostContentView: View {
    let posts: [Post]
    let isLoading: Bool
    let emptyMessage: String
    
    var body: some View {
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
                        Text(emptyMessage)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(posts) { post in
                                PostCellView(post: post)
                            }
                        }
                        .padding(.vertical, 12)
                    }
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Post.self, configurations: config)
    
    return HomeView()
        .modelContainer(container)
}

