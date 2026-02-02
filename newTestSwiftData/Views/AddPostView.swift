//
//  AddPostView.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/23.
//

import SwiftUI
import SwiftData
import PhotosUI

/// 添加帖子视图（重写版本）
/// 支持：
/// 1. 图片和视频选择（PhotosPicker）
/// 2. Mock API 网络请求模拟
/// 3. Access Token 验证
/// 4. 本地存储
struct AddPostView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    /// 发布成功回调（用于刷新首页列表）
    var onPostPublished: (() -> Void)?
    
    // MARK: - 状态变量
    
    @State private var text = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var selectedVideoItem: PhotosPickerItem?
    @State private var localImagePaths: [String] = []
    @State private var localVideoPath: String = ""
    
    @State private var isProcessing = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    @State private var uploadProgress: Double = 0.0
    @State private var currentStep = ""
    
    // MARK: - 预览图片
    
    @State private var previewImages: [UIImage] = []
    @State private var videoThumbnail: UIImage?
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // 用户信息卡片
                        userInfoCard
                        
                        // 文字输入区域
                        textInputSection
                        
                        // 媒体选择区域
                        mediaSelectionSection
                        
                        // 图片预览
                        if !previewImages.isEmpty {
                            imagePreviewSection
                        }
                        
                        // 视频预览
                        if let thumbnail = videoThumbnail {
                            videoPreviewSection(thumbnail: thumbnail)
                        }
                        
                        // 提示信息
                        tipsSection
                    }
                    .padding()
                }
                
                // 加载遮罩
                if isProcessing {
                    loadingOverlay
                }
            }
            .navigationTitle("发布帖子")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .disabled(isProcessing)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("发布") {
                        Task {
                            await publishPost()
                        }
                    }
                    .disabled(text.isEmpty || isProcessing)
                    .fontWeight(.semibold)
                }
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("确定", role: .cancel) {
                    if alertTitle == "发布成功" {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
        .onChange(of: selectedPhotos) { _, newItems in
            Task {
                await loadPhotos(from: newItems)
            }
        }
        .onChange(of: selectedVideoItem) { _, newItem in
            Task {
                await loadVideo(from: newItem)
            }
        }
    }
    
    // MARK: - UI 组件
    
    /// 用户信息卡片
    private var userInfoCard: some View {
        HStack(spacing: 12) {
            // 头像
            Circle()
                .fill(LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 50, height: 50)
                .overlay {
                    Text(authManager.username.prefix(1).uppercased())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(authManager.username)
                    .font(.headline)
                
                Text("准备发布新帖子")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 本地标识
            Label("本地", systemImage: "person.fill")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    /// 文字输入区域
    private var textInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("内容")
                .font(.headline)
            
            TextEditor(text: $text)
                .frame(minHeight: 120)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            
            HStack {
                Text("\(text.count) 字")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if text.count > 500 {
                    Text("建议不超过 500 字")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
    }
    
    /// 媒体选择区域
    private var mediaSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("媒体")
                .font(.headline)
            
            HStack(spacing: 16) {
                // 图片选择
                PhotosPicker(
                    selection: $selectedPhotos,
                    maxSelectionCount: 9,
                    matching: .images
                ) {
                    Label("选择图片", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(10)
                }
                .disabled(!localVideoPath.isEmpty)
                
                // 视频选择
                PhotosPicker(
                    selection: $selectedVideoItem,
                    matching: .videos
                ) {
                    Label("选择视频", systemImage: "video.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .foregroundColor(.purple)
                        .cornerRadius(10)
                }
                .disabled(!localImagePaths.isEmpty)
            }
            
            // 媒体状态提示
            if !localImagePaths.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("已选择 \(localImagePaths.count) 张图片")
                        .font(.caption)
                    Spacer()
                    Button("清除") {
                        clearImages()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }
            
            if !localVideoPath.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("已选择视频")
                        .font(.caption)
                    Spacer()
                    Button("清除") {
                        clearVideo()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }
        }
    }
    
    /// 图片预览区域
    private var imagePreviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("图片预览")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(previewImages.enumerated()), id: \.offset) { index, image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                    }
                }
            }
        }
    }
    
    /// 视频预览区域
    private func videoPreviewSection(thumbnail: UIImage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("视频预览")
                .font(.headline)
            
            ZStack {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // 播放图标
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
                    .shadow(radius: 5)
            }
        }
    }
    
    /// 提示信息
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("提示", systemImage: "info.circle")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("• 图片和视频只能选择其一")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("• 最多可选择 9 张图片")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("• 发布的内容将保存在本地")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("• 使用 Mock API 模拟网络传输")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    /// 加载遮罩
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                VStack(spacing: 8) {
                    Text(currentStep)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if uploadProgress > 0 {
                        ProgressView(value: uploadProgress, total: 1.0)
                            .tint(.white)
                            .frame(width: 200)
                        
                        Text("\(Int(uploadProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .padding(30)
            .background(Color(.systemGray))
            .cornerRadius(15)
            .shadow(radius: 20)
        }
    }
    
    // MARK: - 数据处理方法
    
    /// 加载图片
    private func loadPhotos(from items: [PhotosPickerItem]) async {
        localImagePaths.removeAll()
        previewImages.removeAll()
        
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                // 保存到本地
                if let path = MediaManager.shared.saveImage(data: data) {
                    localImagePaths.append(path)
                    
                    // 生成预览图
                    if let image = UIImage(data: data) {
                        await MainActor.run {
                            previewImages.append(image)
                        }
                    }
                }
            }
        }
        
        print("✅ 已加载 \(localImagePaths.count) 张图片")
    }
    
    /// 加载视频
    private func loadVideo(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        if let data = try? await item.loadTransferable(type: Data.self) {
            // 保存到本地
            if let path = MediaManager.shared.saveVideo(data: data) {
                localVideoPath = path
                
                // 生成缩略图
                if let thumbnail = MediaManager.shared.generateVideoThumbnail(relativePath: path) {
                    await MainActor.run {
                        videoThumbnail = thumbnail
                    }
                }
                
                print("✅ 已加载视频: \(path)")
            }
        }
    }
    
    /// 清除图片
    private func clearImages() {
        // 删除本地文件
        MediaManager.shared.deleteMediaFiles(relativePaths: localImagePaths)
        
        localImagePaths.removeAll()
        previewImages.removeAll()
        selectedPhotos.removeAll()
    }
    
    /// 清除视频
    private func clearVideo() {
        // 删除本地文件
        if !localVideoPath.isEmpty {
            MediaManager.shared.deleteMedia(relativePath: localVideoPath)
        }
        
        localVideoPath = ""
        videoThumbnail = nil
        selectedVideoItem = nil
    }
    
    // MARK: - 发布帖子
    
    /// 发布帖子（完整流程）
    private func publishPost() async {
        isProcessing = true
        uploadProgress = 0.0
        
        // 步骤 1: 验证登录状态
        currentStep = "验证登录状态..."
        await Task.sleep(300_000_000) // 0.3 秒
        
        guard authManager.isLoggedIn else {
            await showError(title: "未登录", message: "请先登录后再发布帖子")
            isProcessing = false
            return
        }
        
        uploadProgress = 0.2
        
        // 步骤 2: 准备请求数据
        currentStep = "准备数据..."
        await Task.sleep(300_000_000)
        
        let request = CreatePostRequest(
            text: text,
            images: localImagePaths,
            videoUrl: localVideoPath
        )
        
        uploadProgress = 0.4
        
        // 步骤 3: 调用 Mock API（模拟网络请求）
        currentStep = "发送到服务器..."
        
        await withCheckedContinuation { continuation in
            MockPostAPIService.shared.createPost(
                request: request,
                accessToken: authManager.accessToken
            ) { result in
                continuation.resume()
                
                Task {
                    await handleAPIResponse(result: result)
                }
            }
        }
    }
    
    /// 处理 API 响应
    private func handleAPIResponse(result: MockAPIResult<CreatePostResponse>) async {
        uploadProgress = 0.8
        currentStep = "保存到本地..."
        
        switch result {
        case .success(let response):
            // API 调用成功，保存到本地
            await savePostLocally(response: response)
            
        case .failure(let error):
            // API 调用失败
            await handleAPIError(error: error)
        }
    }
    
    /// 保存帖子到本地
    private func savePostLocally(response: CreatePostResponse) async {
        // 创建 Post 对象
        let newPost = Post(
            id: response.postId,
            avatar: "local://default_avatar",
            vip: false,
            name: authManager.username,
            date: response.createdAt,
            isFollowed: false,
            text: text,
            images: localImagePaths,
            commentCount: 0,
            likeCount: 0,
            isLiked: false,
            videoUrl: localVideoPath
        )
        
        // 保存到 SwiftData
        await MainActor.run {
            modelContext.insert(newPost)
            
            do {
                try modelContext.save()
                print("✅ 帖子已保存到 SwiftData，ID: \(response.postId)")
            } catch {
                print("❌ 保存到 SwiftData 失败: \(error)")
            }
        }
        
        // 保存到 JSON 文件
        UserPostManager.shared.saveUserPost(newPost, modelContext: modelContext)
        
        uploadProgress = 1.0
        currentStep = "完成！"
        
        await Task.sleep(500_000_000) // 0.5 秒
        
        // 显示成功提示
        await showSuccess(message: "帖子发布成功！\nID: \(response.postId)")
    }
    
    /// 处理 API 错误
    private func handleAPIError(error: MockAPIError) async {
        isProcessing = false
        
        var message = error.message
        
        // 特殊处理 Token 过期
        if error.code == 401 {
            message += "\n\n是否需要刷新登录？"
            
            // 可以在这里添加刷新 Token 的逻辑
            authManager.refreshAccessToken { success in
                if success {
                    print("✅ Token 已刷新，请重试")
                }
            }
        }
        
        await showError(title: "发布失败", message: message)
    }
    
    // MARK: - 辅助方法
    
    /// 显示成功提示
    @MainActor
    private func showSuccess(message: String) {
        isProcessing = false
        alertTitle = "发布成功"
        alertMessage = message
        showAlert = true
        
        // 触发刷新回调
        onPostPublished?()
    }
    
    /// 显示错误提示
    @MainActor
    private func showError(title: String, message: String) {
        isProcessing = false
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

// MARK: - 预览

#Preview {
    AddPostView()
        .environmentObject(AuthManager.shared)
        .modelContainer(for: [Post.self, User.self, Token.self])
}
