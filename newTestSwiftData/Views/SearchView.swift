//
//  SearchView.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/30.
//

import SwiftUI
import SwiftData

/// 搜索视图 - 类似 Google 搜索的交互效果
struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var searchResults: [Post] = []
    @State private var isSearching = false
    @State private var hasSearched = false
    @FocusState private var isSearchFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景色
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 搜索栏 - 根据状态调整位置
                    VStack(spacing: 0) {
                        if !hasSearched {
                            Spacer()
                        } else {
                            Spacer()
                                .frame(height: 20)
                        }
                        
                        // 搜索输入框
                        HStack(spacing: 12) {
                            // 放大镜图标 - 可点击搜索
                            Button(action: {
                                performSearch()
                            }) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(searchText.isEmpty ? .gray : .blue)
                                    .font(.system(size: 20))
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(searchText.trimmingCharacters(in: .whitespaces).isEmpty)
                            
                            TextField("搜索帖子内容或用户名", text: $searchText)
                                .focused($isSearchFieldFocused)
                                .font(.system(size: 17))
                                .submitLabel(.search)
                                .onSubmit {
                                    performSearch()
                                }
                            
                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                    searchResults = []
                                    hasSearched = false
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 18))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                        .padding(.horizontal, 20)
                        
                        if !hasSearched {
                            Spacer()
                        }
                    }
                    .frame(maxHeight: hasSearched ? nil : .infinity)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: hasSearched)
                    
                    // 搜索结果列表
                    if hasSearched {
                        if isSearching {
                            // 加载状态
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("搜索中...")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .transition(.opacity)
                        } else if searchResults.isEmpty {
                            // 空状态
                            VStack(spacing: 16) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                Text("未找到相关帖子")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text("试试其他关键词")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .transition(.opacity)
                        } else {
                            // 结果列表
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(searchResults) { post in
                                        NavigationLink(destination: 
                                            PostDetailView(post: post)
                                                .navigationBarTitleDisplayMode(.inline)
                                        ) {
                                            SearchResultPostCell(post: post, keyword: searchText)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                                .padding(.bottom, 20)
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("返回")
                                .font(.system(size: 17))
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    if hasSearched {
                        Text("搜索结果")
                            .font(.headline)
                    }
                }
            }
            .onAppear {
                // 自动聚焦搜索框
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isSearchFieldFocused = true
                }
            }
        }
    }
    
    /// 执行搜索
    private func performSearch() {
        // 验证输入不为空（去除空格）
        let trimmedText = searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmedText.isEmpty else {
            // 显示提示（可选）
            print("⚠️ 搜索内容不能为空")
            return
        }
        
        // 收起键盘
        isSearchFieldFocused = false
        
        // 添加触觉反馈
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            hasSearched = true
            isSearching = true
        }
        
        // 模拟网络延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            searchPosts()
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isSearching = false
            }
        }
    }
    
    /// 在 SwiftData 中搜索帖子
    private func searchPosts() {
        let keyword = searchText.trimmingCharacters(in: .whitespaces)
        
        do {
            // 使用 FetchDescriptor 查询所有帖子
            let descriptor = FetchDescriptor<Post>(sortBy: [SortDescriptor(\.id, order: .forward)])
            let allPosts = try modelContext.fetch(descriptor)
            
            // 在内存中过滤（不区分大小写）
            searchResults = allPosts.filter { post in
                post.text.localizedCaseInsensitiveContains(keyword) ||
                post.name.localizedCaseInsensitiveContains(keyword)
            }
            
            print("🔍 搜索关键词: \(keyword)")
            print("✅ 找到 \(searchResults.count) 条结果")
            
        } catch {
            print("❌ 搜索失败: \(error.localizedDescription)")
            searchResults = []
        }
    }
}

/// 搜索结果帖子单元格 - 带高亮显示
struct SearchResultPostCell: View {
    @Bindable var post: Post
    let keyword: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 用户信息区域
            HStack(alignment: .center, spacing: 12) {
                // 头像
                NetworkImageView(imageURL: post.avatar)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        // 用户名高亮
                        HighlightedText(
                            text: post.name,
                            keyword: keyword,
                            font: .system(size: 16, weight: .semibold)
                        )
                        
                        if post.vip {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }
                    
                    Text(post.date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // 帖子内容 - 高亮关键词
            HighlightedText(
                text: post.text,
                keyword: keyword,
                font: .body
            )
            .lineLimit(3)
            .foregroundColor(.primary)
            
            // 缩略图（如果有）
            if !post.images.isEmpty {
                NetworkImageView(imageURL: post.images[0])
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .cornerRadius(8)
            } else if post.hasVideo {
                ZStack {
                    Color.black.opacity(0.1)
                    
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                .frame(height: 120)
                .frame(maxWidth: .infinity)
                .cornerRadius(8)
            }
            
            // 互动数据
            HStack(spacing: 20) {
                Label("\(post.likeCount)", systemImage: post.isLiked ? "heart.fill" : "heart")
                    .font(.caption)
                    .foregroundColor(post.isLiked ? .red : .secondary)
                
                Label("\(post.commentCount)", systemImage: "message")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Post.self, configurations: config)
    
    // 添加测试数据
    let context = container.mainContext
    let testPost = Post(
        id: 1,
        avatar: "https://picsum.photos/200",
        vip: true,
        name: "测试用户",
        date: "2026-01-30 10:00",
        isFollowed: false,
        text: "这是一条测试帖子，包含一些测试内容。SwiftUI 真的很强大！",
        images: ["https://picsum.photos/400"],
        commentCount: 10,
        likeCount: 100,
        isLiked: false
    )
    context.insert(testPost)
    
    return SearchView()
        .modelContainer(container)
}

