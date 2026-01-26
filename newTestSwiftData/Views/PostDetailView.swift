//
//  PostDetailView.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/25.
//

import SwiftUI
import SwiftData

/// 帖子详情视图
struct PostDetailView: View {
    @Bindable var post: Post
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    /// 格式化数字显示（1000+ 显示为 1k+，1000000+ 显示为 1M+）
    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            let millions = Double(count) / 1_000_000.0
            return String(format: "%.1fM+", millions)
        } else if count >= 1_000 {
            let thousands = Double(count) / 1_000.0
            return String(format: "%.1fk+", thousands)
        } else {
            return "\(count)"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // 帖子内容区域
                VStack(alignment: .leading, spacing: 12) {
                    // 用户信息区域
                    HStack(alignment: .center, spacing: 12) {
                        // 头像 - 使用网络图片加载
                        NetworkImageView(imageURL: post.avatar)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Text(post.name)
                                    .font(.headline)
                                
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
                        
                        // 关注按钮 - 紧贴最右边
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                post.isFollowed.toggle()
                            }
                        }) {
                            Text(post.isFollowed ? "已关注" : "关注")
                                .font(.system(size: 14))
                                .foregroundColor(post.isFollowed ? .gray : .white)
                                .frame(width: 60, height: 28)
                                .background(post.isFollowed ? Color.gray.opacity(0.2) : Color.blue)
                                .cornerRadius(14)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // 文本内容
                    Text(post.text)
                        .font(.body)
                        .lineLimit(nil)
                        .padding(.top, 4)
                    
                    // 图片网格
                    if !post.images.isEmpty {
                        let screenWidth = UIScreen.main.bounds.width
                        let imageWidth = screenWidth - 32
                        PostImageCell(images: post.images, width: imageWidth)
                            .frame(height: calculateImageHeight(images: post.images, width: imageWidth))
                            .padding(.top, 8)
                    }
                    
                    // 互动区域
                    HStack(spacing: 0) {
                        
                        Spacer()
                        
                        PostCellToolbarButton(
                            image: post.isLiked ? "heart.fill" : "heart",
                            text: formatCount(post.likeCount),
                            color: post.isLiked ? .red : .black)
                        {
                            if post.isLiked {
                                post.isLiked = false
                                post.likeCount -= 1
                            } else {
                                post.isLiked = true
                                post.likeCount += 1
                            }
                        }
                        
                        Spacer()
                        
                        PostCellToolbarButton(
                            image: "message",
                            text: formatCount(post.commentCount),
                            color: .black)
                        {
                            print("点击评论")
                        }
                        
                        Spacer()
                        
                        PostCellToolbarButton(
                            image: "arrowshape.turn.up.right",
                            text: "转发",
                            color: .black)
                        {
                            print("点击转发")
                        }
                        
                        Spacer()
                        
                    }
                    .padding(.top, 12)
                }
                .padding(16)
                .background(Color(.systemBackground))
                
                Divider()
                    .padding(.vertical, 8)
                
                // 评论区域
                VStack(alignment: .leading, spacing: 16) {
                    Text("评论 \(post.commentCount)")
                        .font(.headline)
                        .padding(.horizontal, 16)
                    
                    // 模拟评论列表
                    ForEach(0..<5, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 40, height: 40)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("用户\(index + 1)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Text("这是一条评论内容...")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                        }
                        
                        if index < 4 {
                            Divider()
                                .padding(.leading, 68)
                        }
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("详情")
        .onChange(of: post.isLiked) { _, _ in
            // 点赞状态改变时同步到 JSON
            Task {
                try? modelContext.save()
                JSONService.savePostsToJSON(fileName: "PostListData_recommend_1.json", modelContext: modelContext)
            }
        }
    }
    
    /// 计算图片区域的高度
    private func calculateImageHeight(images: [String], width: CGFloat) -> CGFloat {
        let imageSpace: CGFloat = 6
        let singleImageHeight = width * 0.75
        
        switch images.count {
        case 1:
            return singleImageHeight
        case 2, 3:
            return (width - imageSpace * CGFloat(images.count - 1)) / CGFloat(images.count)
        case 4:
            let rowHeight = (width - imageSpace) / 2
            return rowHeight * 2 + imageSpace
        case 5:
            let rowHeight = (width - imageSpace) / 2
            let bottomRowHeight = (width - imageSpace * 2) / 3
            return rowHeight + bottomRowHeight + imageSpace
        case 6:
            let rowHeight = (width - imageSpace * 2) / 3
            return rowHeight * 2 + imageSpace
        default:
            let rowHeight = (width - imageSpace * 2) / 3
            return rowHeight * 2 + imageSpace
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Post.self, configurations: config)
    let context = ModelContext(container)
    
    // 创建测试数据
    let testPost = Post(
        id: 1,
        avatar: "test.jpg",
        vip: true,
        name: "测试用户",
        date: "2026-01-25",
        isFollowed: false,
        text: "这是一条测试帖子内容",
        images: [],
        commentCount: 100,
        likeCount: 500,
        isLiked: false
    )
    context.insert(testPost)
    
    return NavigationView {
        PostDetailView(post: testPost)
    }
    .modelContainer(container)
}

