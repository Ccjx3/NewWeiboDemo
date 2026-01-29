//
//  CommentInputView.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/29.
//

import SwiftUI
import SwiftData

/// 评论输入界面
/// 提供完整的评论输入功能，包括文本输入区域和操作按钮
struct CommentInputView: View {
    /// 被评论的帖子
    let post: Post
    
    /// 发送成功回调
    let onSendSuccess: () -> Void
    
    /// 控制视图关闭
    @Environment(\.presentationMode) var presentationMode
    
    /// 输入的评论内容
    @State private var text: String = ""
    
    /// 空内容提示状态
    @State private var showEmptyTextHUD: Bool = false
    
    /// 字数限制
    private let maxCharacterCount: Int = 500
    
    var body: some View {
        VStack(spacing: 0) {
            // 1️⃣ 文本输入区域
            CommentTextView(text: $text, beginEdittingOnAppear: true)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // 2️⃣ 字数统计区域
            HStack {
                Text("\(text.count)/\(maxCharacterCount)")
                    .font(.system(size: 14))
                    .foregroundColor(text.count > maxCharacterCount ? .red : .gray)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                
                Spacer()
            }
            .background(Color(.systemGray6))
            
            // 3️⃣ 底部操作栏
            HStack(spacing: 0) {
                // 取消按钮
                Button {
                    print("🔘 点击取消按钮")
                    self.presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("取消")
                        .padding()
                }
                
                Spacer()
                
                // 发送按钮
                Button {
                    print("🔘 点击发送按钮")
                    handleSendComment()
                } label: {
                    Text("发送")
                        .padding()
                }
            }
            .font(.system(size: 18))
            .foregroundColor(.black)
        }
        // 4️⃣ 提示信息覆盖层
        .overlay {
            // 空内容提示
            if showEmptyTextHUD {
                HUDView(message: "评论不能为空", isVisible: showEmptyTextHUD)
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// 处理发送评论
    private func handleSendComment() {
        // ✅ 验证输入 - 去除空格和换行符后判断是否为空
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedText.isEmpty {
            print("⚠️ 评论内容为空")
            // 显示提示
            showEmptyTextHUD = true
            
            // 1 秒后自动隐藏
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                showEmptyTextHUD = false
            }
            return
        }
        
        // ✅ 检查字数限制
        if trimmedText.count > maxCharacterCount {
            print("⚠️ 评论内容超过字数限制")
            showEmptyTextHUD = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                showEmptyTextHUD = false
            }
            return
        }
        
        // ✅ 输入合法，打印评论内容
        print("✅ 评论内容合法")
        print("📝 评论内容: \(trimmedText)")
        print("📝 评论帖子ID: \(post.id)")
        print("📝 评论字数: \(trimmedText.count)")
        
        // 先关闭弹窗
        self.presentationMode.wrappedValue.dismiss()
        
        // 延迟一点时间后触发成功回调（等待弹窗关闭动画完成）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onSendSuccess()
        }
    }
}

// MARK: - HUD View

/// 提示信息视图组件
struct HUDView: View {
    let message: String
    let isVisible: Bool
    
    var body: some View {
        Text(message)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.75))
            )
            .scaleEffect(isVisible ? 1 : 0.5)
            .opacity(isVisible ? 1 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isVisible)
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
        text: "这是一条测试帖子",
        images: [],
        commentCount: 10,
        likeCount: 100,
        isLiked: false
    )
    
    return CommentInputView(post: samplePost, onSendSuccess: {
        print("发送成功回调")
    })
    .modelContainer(container)
}

