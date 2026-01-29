//
//  ShareInputView.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/29.
//

import SwiftUI
import SwiftData

/// 转发选择界面
/// 提供类似微博/小红书的转发目标选择功能
struct ShareInputView: View {
    /// 被转发的帖子
    let post: Post
    
    /// 转发成功回调
    let onShareSuccess: () -> Void
    
    /// 控制视图关闭
    @Environment(\.presentationMode) var presentationMode
    
    /// 转发目标数据模型
    struct ShareTarget: Identifiable {
        let id: String
        let icon: String
        let name: String
        let color: Color
    }
    
    /// 可转发的目标列表
    private let shareTargets: [ShareTarget] = [
        ShareTarget(id: "wechat", icon: "message.fill", name: "微信好友", color: .green),
        ShareTarget(id: "moments", icon: "circle.grid.2x2.fill", name: "朋友圈", color: .blue),
        ShareTarget(id: "weibo", icon: "w.circle.fill", name: "微博", color: .orange),
        ShareTarget(id: "qq", icon: "q.circle.fill", name: "QQ好友", color: .cyan),
        ShareTarget(id: "qzone", icon: "star.circle.fill", name: "QQ空间", color: .yellow),
        ShareTarget(id: "douyin", icon: "music.note", name: "抖音", color: .black),
        ShareTarget(id: "xiaohongshu", icon: "book.fill", name: "小红书", color: .red),
        ShareTarget(id: "link", icon: "link.circle.fill", name: "复制链接", color: .gray)
    ]
    
    /// 网格布局配置
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // 1️⃣ 顶部标题栏
            HStack {
                Text("分享到")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button {
                    print("🔘 点击关闭按钮")
                    self.presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray.opacity(0.6))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            
            Divider()
            
            // 2️⃣ 帖子预览区域
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    // 头像
                    NetworkImageView(imageURL: post.avatar)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(post.name)
                            .font(.system(size: 15, weight: .medium))
                        
                        Text(post.date)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // 帖子内容预览
                Text(post.text)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            // 3️⃣ 转发目标网格
            ScrollView {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(shareTargets) { target in
                        ShareTargetButton(target: target) {
                            handleShare(to: target)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            
            Spacer()
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Private Methods
    
    /// 处理转发操作
    private func handleShare(to target: ShareTarget) {
        print("📤 转发到: \(target.name)")
        print("📝 帖子ID: \(post.id)")
        print("📝 帖子作者: \(post.name)")
        print("📝 帖子内容: \(post.text)")
        print("📝 转发目标ID: \(target.id)")
        print("✅ 转发操作完成（模拟）")
        
        // 关闭弹窗
        self.presentationMode.wrappedValue.dismiss()
        
        // 延迟触发成功回调
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onShareSuccess()
        }
    }
}

// MARK: - Share Target Button

/// 转发目标按钮组件
struct ShareTargetButton: View {
    let target: ShareInputView.ShareTarget
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // 添加触觉反馈
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            action()
        }) {
            VStack(spacing: 10) {
                // 图标圆形背景
                ZStack {
                    Circle()
                        .fill(target.color.opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: target.icon)
                        .font(.system(size: 28))
                        .foregroundColor(target.color)
                }
                .scaleEffect(isPressed ? 0.9 : 1.0)
                
                // 名称
                Text(target.name)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
}


// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Post.self, configurations: config)
    
    let samplePost = Post(
        id: 1,
        avatar: "avatar1",
        vip: true,
        name: "测试用户",
        date: "2026-01-29 10:00",
        isFollowed: false,
        text: "这是一条测试帖子，用于展示转发功能的效果",
        images: [],
        commentCount: 10,
        likeCount: 100,
        isLiked: false
    )
    
    return ShareInputView(post: samplePost, onShareSuccess: {
        print("转发成功回调")
    })
    .modelContainer(container)
}

