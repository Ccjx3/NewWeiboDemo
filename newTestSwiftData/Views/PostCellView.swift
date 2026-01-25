//
//  PostCellView.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/23.
//

import SwiftUI
import SwiftData

/// 单个帖子单元格视图
struct PostCellView: View {
    @Bindable var post: Post
    @Environment(\.modelContext) private var modelContext
    @State private var showDeletePopover = false
    
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
                
                // 关注按钮和删除按钮区域
                HStack(spacing: 8) {
                    // 关注按钮
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
                    
                    // X 删除按钮
                    Button(action: {
                        print("🔘 点击了删除按钮")
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showDeletePopover.toggle()
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.gray.opacity(0.6))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // 文本内容
            Text(post.text)
                .font(.body)
                .lineLimit(nil)
            
            // 图片网格
            if !post.images.isEmpty {
                let screenWidth = UIScreen.main.bounds.width
                let imageWidth = screenWidth - 32 // 减去左右 padding
                PostImageCell(images: post.images, width: imageWidth)
                    .frame(height: calculateImageHeight(images: post.images, width: imageWidth))
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
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .onChange(of: post.isLiked) { _, _ in
            // 点赞状态改变时同步到 JSON
            Task {
                try? modelContext.save()
                JSONService.savePostsToJSON(fileName: "PostListData_recommend_1.json", modelContext: modelContext)
            }
        }
        .overlay {
            // 透明背景遮罩 - 点击关闭弹窗（必须在弹窗之前添加）
            if showDeletePopover {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        print("🔘 点击了遮罩，关闭弹窗")
                        withAnimation {
                            showDeletePopover = false
                        }
                    }
            }
        }
        .overlay(alignment: .topTrailing) {
            // 删除弹窗 - 使用 overlay 绝对定位（必须在遮罩之后添加，确保在最上层）
            if showDeletePopover {
                DeletePopoverView(
                    onDelete: {
                        print("🗑️ 开始删除帖子: \(post.id)")
                        // 根据帖子ID判断属于哪个列表
                        let fileName: String
                        if post.id >= 1000 && post.id < 2000 {
                            fileName = "PostListData_recommend_1.json"
                            print("📝 删除推荐列表帖子")
                        } else if post.id >= 2000 && post.id < 3000 {
                            fileName = "PostListData_hot_1.json"
                            print("📝 删除热门列表帖子")
                        } else {
                            fileName = "PostListData_recommend_1.json"
                            print("⚠️ 未知ID范围，默认使用推荐列表")
                        }
                        
                        // 先关闭弹窗
                        withAnimation {
                            showDeletePopover = false
                        }
                        
                        // 延迟删除，确保动画完成
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation {
                                modelContext.delete(post)
                                do {
                                    try modelContext.save()
                                    print("✅ 帖子从SwiftData删除成功")
                                    print("删除成功")
                                    
                                    // 同步到对应的JSON文件
                                    JSONService.savePostsToJSON(fileName: fileName, modelContext: modelContext)
                                    print("✅ 已同步到JSON文件: \(fileName)")
                                } catch {
                                    print("❌ 删除失败: \(error)")
                                }
                            }
                        }
                    },
                    onDismiss: {
                        withAnimation {
                            showDeletePopover = false
                        }
                    }
                )
                .offset(x: -20, y: 45)
                .transition(.scale(scale: 0.8, anchor: .top).combined(with: .opacity))
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
            // 超过 6 张，显示前 6 张
            let rowHeight = (width - imageSpace * 2) / 3
            return rowHeight * 2 + imageSpace
        }
    }
}

/// 删除弹窗视图 - 气泡式设计
struct DeletePopoverView: View {
    let onDelete: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 小三角箭头
            Triangle()
                .fill(Color.white)
                .frame(width: 16, height: 8)
                .offset(x: 30)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: -1)
            
            // 删除按钮
            Button(action: {
                print("🔘 点击了删除确认按钮")
                onDelete()
            }) {
                Text("删除")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
            }
            .buttonStyle(PlainButtonStyle())
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        }
        .frame(width: 100)
        .contentShape(Rectangle())
        .onTapGesture {
            // 阻止事件传递到背景遮罩
            print("🔘 点击了弹窗区域（不关闭）")
        }
    }
}

/// 三角形形状 - 用于气泡箭头
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
