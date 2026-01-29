//
//  UserData.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/29.
//

import Foundation
import SwiftUI
import SwiftData
import Combine

/// 帖子列表分类
enum PostListCategory {
    case recommend  // 推荐
    case hot        // 热门
}

/// 用户数据管理类
/// 负责管理帖子列表的加载、刷新和分页
class UserData: ObservableObject {
    // MARK: - Published Properties
    
    /// 推荐帖子列表
    @Published var recommendPosts: [Post] = []
    
    /// 热门帖子列表
    @Published var hotPosts: [Post] = []
    
    /// 是否正在刷新
    @Published var isRefreshing: Bool = false
    
    /// 是否正在加载更多
    @Published var isLoadingMore: Bool = false
    
    /// 加载错误
    @Published var loadingError: Error?
    
    /// 触发列表重新加载
    @Published var reloadData: Bool = false
    
    // MARK: - Private Properties
    
    /// SwiftData 模型上下文
    var modelContext: ModelContext
    
    /// 推荐列表当前页码
    private var recommendPage: Int = 0
    
    /// 热门列表当前页码
    private var hotPage: Int = 0
    
    /// 每页加载数量
    private let pageSize: Int = 5
    
    /// 推荐帖子去重字典 [postId: index]
    private var recommendPostDic: [Int: Int] = [:]
    
    /// 热门帖子去重字典 [postId: index]
    private var hotPostDic: [Int: Int] = [:]
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public Methods
    
    /// 获取指定分类的帖子列表
    func postList(for category: PostListCategory) -> [Post] {
        switch category {
        case .recommend:
            return recommendPosts
        case .hot:
            return hotPosts
        }
    }
    
    /// 如果需要，加载帖子列表
    func loadPostListIfNeeded(for category: PostListCategory) {
        if postList(for: category).isEmpty {
            refreshPostlist(for: category)
        }
    }
    
    /// 下拉刷新帖子列表
    func refreshPostlist(for category: PostListCategory) {
        // 防止重复刷新
        guard !isRefreshing else { return }
        
        isRefreshing = true
        
        // 重置页码
        switch category {
        case .recommend:
            recommendPage = 0
        case .hot:
            hotPage = 0
        }
        
        // 发起网络请求
        let completion: (Result<PostListResponse, Error>) -> Void = { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case let .success(response):
                    self.handleRefreshPostList(response.list, for: category)
                case let .failure(error):
                    self.handleLoadingError(error)
                }
                self.isRefreshing = false
            }
        }
        
        // 根据分类请求不同的数据
        switch category {
        case .recommend:
            NetworkAPI.recommendPostList(completion: completion)
        case .hot:
            NetworkAPI.hotPostList(completion: completion)
        }
    }
    
    /// 上拉加载更多帖子
    func loadMorePostList(for category: PostListCategory) {
        // 防止重复加载
        guard !isLoadingMore else { 
            print("⚠️ 正在加载中，跳过重复请求")
            return 
        }
        
        // 限制最大加载数量（可选）
        let currentList = postList(for: category)
        if currentList.count >= 50 {
            print("⚠️ 已达到最大加载数量限制")
            return
        }
        
        isLoadingMore = true
        
        print("📥 开始加载更多 \(category == .recommend ? "推荐" : "热门") 数据...")
        
        // 发起网络请求
        let completion: (Result<PostListResponse, Error>) -> Void = { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case let .success(response):
                    self.handleLoadMorePostList(response.list, for: category)
                    // 只有成功加载后才增加页码
                    switch category {
                    case .recommend:
                        self.recommendPage += 1
                    case .hot:
                        self.hotPage += 1
                    }
                case let .failure(error):
                    self.handleLoadingError(error)
                }
                self.isLoadingMore = false
            }
        }
        
        // 根据分类请求对应的数据
        switch category {
        case .recommend:
            // 推荐列表加载更多时，从推荐数据中获取
            NetworkAPI.recommendPostList(completion: completion)
        case .hot:
            // 热门列表加载更多时，从热门数据中获取
            NetworkAPI.hotPostList(completion: completion)
        }
    }
    
    // MARK: - Private Methods
    
    /// 处理刷新数据（清空并重新加载）
    private func handleRefreshPostList(_ list: [PostData], for category: PostListCategory) {
        var tempList: [Post] = []
        var tempDic: [Int: Int] = [:]
        
        // 只取前 pageSize 条数据
        let limitedList = Array(list.prefix(pageSize))
        
        print("📊 开始刷新 \(category == .recommend ? "推荐" : "热门") 列表，共 \(list.count) 条数据，取前 \(pageSize) 条")
        
        // 去重并转换为 Post 对象
        for (index, postData) in limitedList.enumerated() {
            // 检查是否在当前批次中重复
            if tempDic[postData.id] != nil {
                print("⚠️ 跳过重复帖子 ID: \(postData.id)")
                continue
            }
            
            // 从数据库查找或创建新的 Post
            let post = findOrCreatePost(from: postData)
            tempList.append(post)
            tempDic[postData.id] = tempList.count - 1
        }
        
        // 使用动画更新 UI
        withAnimation(.easeInOut(duration: 0.25)) {
            // 更新对应分类的数据
            switch category {
            case .recommend:
                recommendPosts = tempList
                recommendPostDic = tempDic
                recommendPage = 0
            case .hot:
                hotPosts = tempList
                hotPostDic = tempDic
                hotPage = 0
            }
        }
        
        // 触发列表重新加载
        reloadData = true
        
        print("✅ 刷新完成，加载了 \(tempList.count) 条帖子")
    }
    
    /// 处理加载更多数据（追加到列表末尾）
    private func handleLoadMorePostList(_ list: [PostData], for category: PostListCategory) {
        var addedCount = 0
        var skippedCount = 0
        
        // 获取当前页码（注意：此时页码还未增加）
        let currentPage = category == .recommend ? recommendPage : hotPage
        
        // 计算应该跳过多少条数据
        let skipCount = (currentPage + 1) * pageSize
        
        print("📊 加载更多 \(category == .recommend ? "推荐" : "热门") 列表")
        print("   当前页码: \(currentPage)，已加载: \((currentPage + 1) * pageSize) 条，跳过: \(skipCount) 条")
        print("   数据源总数: \(list.count) 条")
        
        // 跳过已加载的数据，只取接下来的 pageSize 条
        let limitedList = Array(list.dropFirst(skipCount).prefix(pageSize))
        
        print("   本次获取: \(limitedList.count) 条数据")
        
        if limitedList.isEmpty {
            print("⚠️ 没有更多数据了")
            return
        }
        
        // 准备新帖子数组
        var newPosts: [Post] = []
        
        for postData in limitedList {
            // 去重检查
            let isDuplicate = category == .recommend ? 
                recommendPostDic[postData.id] != nil : 
                hotPostDic[postData.id] != nil
            
            if isDuplicate {
                print("⚠️ 跳过重复帖子 ID: \(postData.id)")
                skippedCount += 1
                continue
            }
            
            // 从数据库查找或创建新的 Post
            let post = findOrCreatePost(from: postData)
            newPosts.append(post)
            print("✅ 添加帖子 ID: \(postData.id)")
            addedCount += 1
        }
        
        // 使用动画更新 UI
        withAnimation(.easeInOut(duration: 0.3)) {
            switch category {
            case .recommend:
                for post in newPosts {
                    recommendPosts.append(post)
                    recommendPostDic[post.id] = recommendPosts.count - 1
                }
            case .hot:
                for post in newPosts {
                    hotPosts.append(post)
                    hotPostDic[post.id] = hotPosts.count - 1
                }
            }
        }
        
        print("✅ 加载更多完成，新增了 \(addedCount) 条帖子，跳过了 \(skippedCount) 条重复帖子")
        print("   当前列表总数: \(category == .recommend ? recommendPosts.count : hotPosts.count) 条")
    }
    
    /// 从数据库查找或创建新的 Post
    private func findOrCreatePost(from postData: PostData) -> Post {
        // 先尝试从数据库查找
        let postId = postData.id
        let descriptor = FetchDescriptor<Post>(
            predicate: #Predicate<Post> { p in
                p.id == postId
            }
        )
        
        do {
            let existingPosts = try modelContext.fetch(descriptor)
            if let existingPost = existingPosts.first {
                // 更新现有帖子的数据
                existingPost.likeCount = postData.likeCount
                existingPost.isLiked = postData.isLiked
                existingPost.commentCount = postData.commentCount
                existingPost.isFollowed = postData.isFollowed
                return existingPost
            }
        } catch {
            print("⚠️ 查询帖子失败: \(error.localizedDescription)")
        }
        
        // 如果不存在，创建新的 Post
        let newPost = Post(
            id: postData.id,
            avatar: postData.avatar,
            vip: postData.vip,
            name: postData.name,
            date: postData.date,
            isFollowed: postData.isFollowed,
            text: postData.text,
            images: postData.images,
            commentCount: postData.commentCount,
            likeCount: postData.likeCount,
            isLiked: postData.isLiked,
            videoUrl: postData.videoUrl ?? ""
        )
        
        // 插入到数据库
        modelContext.insert(newPost)
        
        do {
            try modelContext.save()
        } catch {
            print("⚠️ 保存帖子失败: \(error.localizedDescription)")
        }
        
        return newPost
    }
    
    /// 处理加载错误
    private func handleLoadingError(_ error: Error) {
        loadingError = error
        print("❌ 加载失败: \(error.localizedDescription)")
        
        // 1.5 秒后自动清除错误
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.loadingError = nil
        }
    }
}

