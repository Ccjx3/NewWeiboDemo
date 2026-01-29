//
//  HomeView.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/25.
//

import SwiftUI
import SwiftData
import BBSwiftUIKit

/// 主页视图 - 支持推荐和热门内容切换，支持下拉刷新和上拉加载更多
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var userData: UserData
    @State private var leftPercent: CGFloat = 0 // 0 为推荐，1 为热门
    @State private var showingAddPost = false
    @State private var showCommentSuccessHUD = false  // 控制评论成功提示显示
    
    init() {
        // 注意：这里需要在 init 中创建 UserData，但 modelContext 需要从环境中获取
        // 我们使用一个临时的方案，稍后会在 onAppear 中初始化
        let tempConfig = ModelConfiguration(isStoredInMemoryOnly: true)
        let tempContainer = try! ModelContainer(for: Post.self, configurations: tempConfig)
        _userData = StateObject(wrappedValue: UserData(modelContext: tempContainer.mainContext))
    }
    
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
                    PostListContentView(
                        category: .recommend,
                        userData: userData,
                        onCommentSuccess: {
                            showCommentSuccessHUD = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                showCommentSuccessHUD = false
                            }
                        }
                    )
                    .tag(CGFloat(0))
                    
                    // 热门页面
                    PostListContentView(
                        category: .hot,
                        userData: userData,
                        onCommentSuccess: {
                            showCommentSuccessHUD = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                showCommentSuccessHUD = false
                            }
                        }
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
            .onAppear {
                // 使用真实的 modelContext 重新初始化 UserData
                if userData.modelContext.container == nil || userData.modelContext.container.configurations.first?.isStoredInMemoryOnly == true {
                    userData.modelContext = modelContext
                }
            }
            .overlay(
                // 错误提示
                Group {
                    if let error = userData.loadingError {
                        VStack {
                            Text(error.localizedDescription)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(8)
                                .padding()
                            Spacer()
                        }
                        .transition(.move(edge: .top))
                    }
                }
            )
            .overlay {
                // 评论成功提示 - 屏幕正中央，苹果原生风格
                if showCommentSuccessHUD {
                    AppleStyleHUDView(message: "发送成功", isVisible: showCommentSuccessHUD)
                }
            }
        }
    }
}

/// 帖子列表内容视图 - 支持下拉刷新和上拉加载更多
struct PostListContentView: View {
    let category: PostListCategory
    @ObservedObject var userData: UserData
    var onCommentSuccess: (() -> Void)? = nil
    
    var body: some View {
        ZStack(alignment: .bottom) {
            BBTableView(userData.postList(for: category)) { post in
                PostCellWithNavigation(post: post, onCommentSuccess: onCommentSuccess)
                    .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            .bb_setupRefreshControl { control in
                control.attributedTitle = NSAttributedString(
                    string: "加载中...",
                    attributes: [
                        .foregroundColor: UIColor.systemGray,
                        .font: UIFont.systemFont(ofSize: 14)
                    ]
                )
                // 优化刷新控件的动画
                control.tintColor = .systemBlue
            }
            .bb_pullDownToRefresh(isRefreshing: $userData.isRefreshing) {
                // 添加触觉反馈
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                
                self.userData.refreshPostlist(for: self.category)
            }
            .bb_pullUpToLoadMore(bottomSpace: 50) {
                // 增加触发距离，让加载更早开始
                self.userData.loadMorePostList(for: self.category)
            }
            .bb_reloadData($userData.reloadData)
            .animation(.easeInOut(duration: 0.3), value: userData.postList(for: category).count)
            .onAppear {
                self.userData.loadPostListIfNeeded(for: self.category)
            }
            
            // 加载更多指示器
            if userData.isLoadingMore {
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(0.9)
                        Text("加载中...")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
                    )
                    .padding(.bottom, 20)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: userData.isLoadingMore)
            }
        }
    }
}

/// 带导航功能的帖子单元格包装器
struct PostCellWithNavigation: View {
    @Bindable var post: Post
    @State private var navigateToDetail = false
    var onCommentSuccess: (() -> Void)? = nil
    
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
            }, onCommentSuccess: onCommentSuccess)
        }
    }
}

/// 苹果原生风格的 HUD 提示视图
struct AppleStyleHUDView: View {
    let message: String
    let isVisible: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text(message)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
        )
        .scaleEffect(isVisible ? 1 : 0.5)
        .opacity(isVisible ? 1 : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isVisible)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Post.self, configurations: config)
    
    HomeView()
        .modelContainer(container)
}


