//
//  UserView.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/29.
//

import SwiftUI
import SwiftData

/// 用户主页视图
struct UserView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthManager.shared
    @State private var selectedTab: Int = 0
    @State private var showLogoutAlert = false
    @State private var showDebugSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // 用户信息卡片
                    UserProfileCard(showLogoutAlert: $showLogoutAlert)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    // 统计数据
                    UserStatsView()
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    // 调试按钮（查看数据库）
                    DebugDatabaseButton(showDebugSheet: $showDebugSheet)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    
                    // 标签切换
                    UserTabSelector(selectedTab: $selectedTab)
                        .padding(.top, 24)
                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    // 内容区域
                    UserContentView(selectedTab: selectedTab)
                        .padding(.top, 16)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("个人主页")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        print("分享个人主页")
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                    }
                }
            }
            .alert("退出登录", isPresented: $showLogoutAlert) {
                Button("取消", role: .cancel) { }
                Button("确定", role: .destructive) {
                    authManager.logout()
                    dismiss()
                }
            } message: {
                Text("确定要退出登录吗？")
            }
            .sheet(isPresented: $showDebugSheet) {
                DatabaseDebugView()
            }
        }
    }
}

/// 调试按钮 - 查看数据库
struct DebugDatabaseButton: View {
    @Binding var showDebugSheet: Bool
    
    var body: some View {
        Button(action: {
            showDebugSheet = true
        }) {
            HStack {
                Image(systemName: "cylinder.split.1x2")
                    .font(.system(size: 16))
                
                Text("查看数据库（调试）")
                    .font(.system(size: 15, weight: .medium))
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .foregroundColor(.orange)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

/// 数据库调试视图
struct DatabaseDebugView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var users: [User] = []
    @State private var tokens: [Token] = []
    @State private var currentTokens: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 标题说明
                    VStack(spacing: 8) {
                        Image(systemName: "cylinder.split.1x2.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("SwiftData 数据库")
                            .font(.system(size: 24, weight: .bold))
                        
                        Text("真实的本地数据库，数据永久保存")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // 用户列表
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "person.3.fill")
                                .foregroundColor(.blue)
                            Text("所有用户账号")
                                .font(.system(size: 18, weight: .semibold))
                            Spacer()
                            Text("\(users.count) 个")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        
                        ForEach(users.indices, id: \.self) { index in
                            SwiftDataUserDebugCard(user: users[index], index: index + 1)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Token 列表
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "key.fill")
                                .foregroundColor(.green)
                            Text("数据库中的 Token")
                                .font(.system(size: 18, weight: .semibold))
                            Spacer()
                            Text("\(tokens.count) 个")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        
                        ForEach(tokens.indices, id: \.self) { index in
                            SwiftDataTokenCard(token: tokens[index])
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 20)
                    
                    // 当前 Keychain Token 信息
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.purple)
                            Text("Keychain 中的 Token")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .padding(.horizontal, 20)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            if let refreshToken = KeychainManager.shared.getRefreshToken() {
                                TokenInfoCard(
                                    title: "Refresh Token",
                                    token: refreshToken,
                                    color: .green
                                )
                            } else {
                                Text("无 Refresh Token")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                            }
                            
                            if let accessToken = KeychainManager.shared.getAccessToken() {
                                TokenInfoCard(
                                    title: "Access Token",
                                    token: accessToken,
                                    color: .blue
                                )
                            } else {
                                Text("无 Access Token")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)
                    
                    // 操作按钮
                    VStack(spacing: 12) {
                        Button(action: {
                            loadData()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("刷新数据")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .cyan]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            cleanExpiredTokens()
                        }) {
                            HStack {
                                Image(systemName: "trash.slash")
                                Text("清理过期 Token")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.orange)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            clearAllTokens()
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("清除所有 Token")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.red)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            printToConsole()
                        }) {
                            HStack {
                                Image(systemName: "terminal")
                                Text("打印到控制台")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.green)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("数据库调试")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadData()
            }
        }
    }
    
    private func loadData() {
        users = SwiftDataAuthService.shared.getAllUsers()
        tokens = SwiftDataAuthService.shared.getAllTokens()
    }
    
    private func cleanExpiredTokens() {
        SwiftDataAuthService.shared.cleanExpiredTokens()
        loadData()
    }
    
    private func clearAllTokens() {
        SwiftDataAuthService.shared.clearAllTokens()
        KeychainManager.shared.clearAll()
        loadData()
    }
    
    private func printToConsole() {
        SwiftDataAuthService.shared.printAllUsers()
    }
}

/// 用户调试卡片（SwiftData 版本）
struct SwiftDataUserDebugCard: View {
    let user: User
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("#\(index)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: user.isPreset ? [.blue, .purple] : [.green, .teal]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(user.username)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        if user.isPreset {
                            Text("预置")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text("ID: \(user.id)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(icon: "envelope.fill", label: "邮箱", value: user.email)
                InfoRow(icon: "lock.fill", label: "密码", value: user.password)
                InfoRow(icon: "calendar", label: "创建时间", value: formatDate(user.createdAt))
                if let lastLogin = user.lastLoginAt {
                    InfoRow(icon: "clock.fill", label: "最后登录", value: formatDate(lastLogin))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

/// Token 调试卡片
struct SwiftDataTokenCard: View {
    let token: Token
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: token.type == "refresh" ? "key.fill" : "key")
                    .foregroundColor(token.type == "refresh" ? .green : .blue)
                
                Text(token.type == "refresh" ? "Refresh Token" : "Access Token")
                    .font(.system(size: 14, weight: .semibold))
                
                Spacer()
                
                if token.isExpired {
                    Text("已过期")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .cornerRadius(4)
                } else {
                    Text("有效")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green)
                        .cornerRadius(4)
                }
            }
            
            if let user = token.user {
                Text("用户: \(user.username) (ID: \(user.id))")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Text(token.tokenString)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(6)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("创建时间")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text(formatDate(token.createdAt))
                        .font(.system(size: 12, weight: .medium))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("过期时间")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text(formatDate(token.expiresAt))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(token.isExpired ? .red : .primary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(token.isExpired ? Color.red.opacity(0.3) : Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

/// 用户调试卡片
struct UserDebugCard: View {
    let user: MockUser
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("#\(index)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.username)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("ID: \(user.id)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(icon: "envelope.fill", label: "邮箱", value: user.email)
                InfoRow(icon: "lock.fill", label: "密码", value: user.password)
                InfoRow(icon: "calendar", label: "创建时间", value: formatDate(user.createdAt))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

/// 信息行
struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

/// Token 信息卡片
struct TokenInfoCard: View {
    let title: String
    let token: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
                
                Spacer()
                
                Button(action: {
                    UIPasteboard.general.string = token
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12))
                        Text("复制")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.blue)
                }
            }
            
            Text(token)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(3)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

/// 用户信息卡片
struct UserProfileCard: View {
    @Binding var showLogoutAlert: Bool
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // 头像
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.4, green: 0.5, blue: 0.9),
                                    Color(red: 0.6, green: 0.3, blue: 0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                
                // 用户信息
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(authManager.username.isEmpty ? "用户昵称" : authManager.username)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                    }
                    
                    Text("ID: 123456789")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text("北京·朝阳区")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // 个人简介
            Text("这是一段个人简介，可以介绍自己的兴趣爱好、职业等信息。")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 操作按钮
            HStack(spacing: 12) {
                Button(action: {
                    print("编辑资料")
                }) {
                    HStack {
                        Image(systemName: "pencil")
                            .font(.system(size: 14))
                        Text("编辑资料")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .cyan]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                }
                
                Button(action: {
                    showLogoutAlert = true
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 14))
                        Text("退出登录")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

/// 用户统计数据视图
struct UserStatsView: View {
    var body: some View {
        HStack(spacing: 0) {
            UserStatItem(title: "关注", value: "128")
            
            Divider()
                .frame(height: 40)
            
            UserStatItem(title: "粉丝", value: "1.2K")
            
            Divider()
                .frame(height: 40)
            
            UserStatItem(title: "获赞", value: "5.6K")
            
            Divider()
                .frame(height: 40)
            
            UserStatItem(title: "收藏", value: "328")
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

/// 单个统计项
struct UserStatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        Button(action: {
            print("点击\(title)")
        }) {
            VStack(spacing: 6) {
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// 标签选择器
struct UserTabSelector: View {
    @Binding var selectedTab: Int
    @Namespace private var animation
    
    let tabs = ["帖子", "收藏", "赞过"]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tabs[index])
                            .font(.system(size: 16, weight: selectedTab == index ? .semibold : .regular))
                            .foregroundColor(selectedTab == index ? .blue : .secondary)
                        
                        if selectedTab == index {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue, .cyan]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 30, height: 3)
                                .matchedGeometryEffect(id: "tab", in: animation)
                        } else {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.clear)
                                .frame(width: 30, height: 3)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
    }
}

/// 用户内容视图
struct UserContentView: View {
    let selectedTab: Int
    
    var body: some View {
        VStack(spacing: 16) {
            if selectedTab == 0 {
                // 帖子列表
                UserPostsGrid()
            } else if selectedTab == 1 {
                // 收藏列表
                UserCollectionsGrid()
            } else {
                // 赞过列表
                UserLikesGrid()
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

/// 用户帖子网格（显示真实的本地帖子）
struct UserPostsGrid: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Post> { post in
        post.id >= 10000  // 只显示本地发布的帖子
    }, sort: \Post.id, order: .reverse) private var userPosts: [Post]
    
    let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        if userPosts.isEmpty {
            // 空状态
            VStack(spacing: 20) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 60))
                    .foregroundColor(.gray.opacity(0.3))
                
                Text("还没有发布帖子")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                
                Text("点击首页的 + 按钮发布你的第一条帖子吧")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
        } else {
            VStack(spacing: 16) {
                // 统计信息
                HStack {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(.blue)
                    Text("我的帖子")
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                    Text("\(userPosts.count) 条")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 4)
                
                // 帖子网格
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(userPosts) { post in
                        NavigationLink(destination: PostDetailView(post: post)) {
                            UserPostGridItem(post: post)
                        }
                    }
                }
            }
        }
    }
}

/// 用户帖子网格项
struct UserPostGridItem: View {
    let post: Post
    @Environment(\.modelContext) private var modelContext
    @State private var showDeleteAlert = false
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // 背景图片或颜色
            if let firstImage = post.images.first, !firstImage.isEmpty {
                // 显示第一张图片
                if let imageURL = MediaManager.shared.getMediaURL(relativePath: firstImage),
                   let uiImage = UIImage(contentsOfFile: imageURL.path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fill)
                        .clipped()
                } else {
                    // 图片加载失败，显示占位符
                    placeholderView
                }
            } else if !post.videoUrl.isEmpty {
                // 显示视频缩略图
                if let thumbnail = MediaManager.shared.generateVideoThumbnail(relativePath: post.videoUrl) {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fill)
                        .clipped()
                        .overlay(
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .shadow(radius: 5)
                        )
                } else {
                    placeholderView
                }
            } else {
                // 纯文字帖子，显示文字预览
                textPreviewView
            }
            
            // 底部信息栏
            HStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 11))
                Text("\(post.likeCount)")
                    .font(.system(size: 11, weight: .medium))
                
                Spacer()
                
                if post.images.count > 1 {
                    HStack(spacing: 2) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 10))
                        Text("\(post.images.count)")
                            .font(.system(size: 11, weight: .medium))
                    }
                }
            }
            .foregroundColor(.white)
            .padding(6)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.6),
                        Color.black.opacity(0.3)
                    ]),
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
        }
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray5), lineWidth: 0.5)
        )
        // 添加删除按钮
        .overlay(alignment: .topTrailing) {
            Button(action: {
                showDeleteAlert = true
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .background(
                        Circle()
                            .fill(Color.red)
                            .frame(width: 20, height: 20)
                    )
                    .shadow(radius: 2)
            }
            .padding(6)
        }
        .alert("删除帖子", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                deletePost()
            }
        } message: {
            Text("确定要删除这条帖子吗？删除后无法恢复。")
        }
    }
    
    /// 删除帖子
    private func deletePost() {
        print("🗑️ 开始删除帖子: ID \(post.id)")
        
        // 1. 删除媒体文件
        MediaManager.shared.deleteMediaFiles(relativePaths: post.images)
        if !post.videoUrl.isEmpty {
            MediaManager.shared.deleteMedia(relativePath: post.videoUrl)
        }
        
        // 2. 从 SwiftData 删除
        modelContext.delete(post)
        
        do {
            try modelContext.save()
            print("✅ 帖子已从 SwiftData 删除")
        } catch {
            print("❌ 删除失败: \(error)")
        }
        
        // 3. 从 JSON 文件删除
        UserPostManager.shared.deleteUserPost(postId: post.id, modelContext: modelContext)
    }
    
    // 占位符视图
    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.3),
                        Color.purple.opacity(0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 30))
                    .foregroundColor(.white.opacity(0.5))
            )
    }
    
    // 文字预览视图
    private var textPreviewView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.95, green: 0.95, blue: 0.97),
                            Color(red: 0.90, green: 0.92, blue: 0.95)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .aspectRatio(1, contentMode: .fit)
            
            VStack(spacing: 8) {
                Image(systemName: "text.alignleft")
                    .font(.system(size: 24))
                    .foregroundColor(.blue.opacity(0.6))
                
                Text(post.text)
                    .font(.system(size: 11))
                    .foregroundColor(.primary.opacity(0.7))
                    .lineLimit(3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
        }
    }
}

/// 用户收藏网格
struct UserCollectionsGrid: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.3))
            
            Text("暂无收藏内容")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

/// 用户点赞网格
struct UserLikesGrid: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.3))
            
            Text("暂无点赞内容")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

#Preview {
    UserView()
}

