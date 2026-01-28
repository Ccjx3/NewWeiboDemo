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
    
    // 查询所有帖子，然后在计算属性中分类
    @Query(sort: \Post.id, order: .forward) private var allPosts: [Post]
    
    // 推荐帖子：ID 1000-1999 或 3000-3029
    private var recommendPosts: [Post] {
        allPosts.filter { post in
            (post.id >= 1000 && post.id < 2000) || (post.id >= 3000 && post.id < 3030)
        }
    }
    
    // 热门帖子：ID 2000-2999 或 3030-3099
    private var hotPosts: [Post] {
        allPosts.filter { post in
            (post.id >= 2000 && post.id < 3000) || (post.id >= 3030 && post.id < 3100)
        }
    }
    
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
        
        // 加载推荐数据 - 使用新的 JSON 文件
        if !hasLoadedRecommend && recommendPosts.isEmpty {
            print("📥 开始加载推荐数据...")
            let loaded = JSONService.loadPostsFromJSON(
                fileName: "PostListData_recommend_2.json",
                modelContext: modelContext
            )
            hasLoadedRecommend = true
            print("✅ 推荐数据加载完成: \(loaded.count) 条")
        }
        
        // 加载热门数据 - 使用新的 JSON 文件
        if !hasLoadedHot && hotPosts.isEmpty {
            print("📥 开始加载热门数据...")
            let loaded = JSONService.loadPostsFromJSON(
                fileName: "PostListData_hot_2.json",
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
                                PostCellWithNavigation(post: post)
                            }
                        }
                        .padding(.vertical, 12)
                    }
                }
            }
        }
    }
}

/// 带导航功能的帖子单元格包装器
struct PostCellWithNavigation: View {
    @Bindable var post: Post
    @State private var navigateToDetail = false
    
    var body: some View {
        ZStack {
            // 隐藏的 NavigationLink
            NavigationLink(destination: PostDetailView(post: post), isActive: $navigateToDetail) {
                EmptyView()
            }
            .hidden()
            
            // 帖子内容
            PostCellView(post: post, onTapContent: {
                // 点击内容区域时导航到详情页
                print("📱 点击帖子内容，准备导航到详情页")
                navigateToDetail = true
            })
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Post.self, configurations: config)
    
    HomeView()
        .modelContainer(container)
}


