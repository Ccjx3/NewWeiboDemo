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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 用户信息区域
            HStack(spacing: 12) {
                // 头像
                ImageLoader.loadImage(from: post.avatar)
                    .resizable()
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
                
                Button(action: {
                    post.isFollowed.toggle()
                }) {
                    Text(post.isFollowed ? "已关注" : "关注")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(post.isFollowed ? Color.gray.opacity(0.2) : Color.blue)
                        .foregroundColor(post.isFollowed ? .primary : .white)
                        .cornerRadius(15)
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
            HStack(spacing: 20) {
                Button(action: {
                    post.isLiked.toggle()
                    if post.isLiked {
                        post.likeCount += 1
                    } else {
                        post.likeCount = max(0, post.likeCount - 1)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: post.isLiked ? "heart.fill" : "heart")
                            .foregroundColor(post.isLiked ? .red : .gray)
                        Text("\(post.likeCount)")
                            .font(.caption)
                    }
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "message")
                        .foregroundColor(.gray)
                    Text("\(post.commentCount)")
                        .font(.caption)
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
