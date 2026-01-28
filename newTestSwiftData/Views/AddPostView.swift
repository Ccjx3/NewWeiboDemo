//
//  AddPostView.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/23.
//

import SwiftUI
import SwiftData

/// 添加帖子视图
struct AddPostView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    /// 当前所在的列表类型（推荐或热门）
    var listType: PostListType = .recommend
    
    @State private var name = ""
    @State private var text = ""
    @State private var avatar = ""
    @State private var images: [String] = []
    @State private var newImageName = ""
    @State private var videoUrl = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("用户信息") {
                    TextField("用户名", text: $name)
                    TextField("头像文件名", text: $avatar)
                }
                
                Section("内容") {
                    TextEditor(text: $text)
                        .frame(height: 100)
                }
                
                Section("视频") {
                    TextField("视频 URL 或文件名", text: $videoUrl)
                    Text("提示：如果添加了视频，图片将不会显示")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("图片") {
                    ForEach(images, id: \.self) { imageName in
                        Text(imageName)
                    }
                    .onDelete(perform: deleteImage)
                    
                    HStack {
                        TextField("图片文件名", text: $newImageName)
                        Button("添加") {
                            if !newImageName.isEmpty {
                                images.append(newImageName)
                                newImageName = ""
                            }
                        }
                    }
                }
            }
            .navigationTitle("添加帖子")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        savePost()
                    }
                    .disabled(name.isEmpty || text.isEmpty)
                }
            }
        }
    }
    
    private func deleteImage(offsets: IndexSet) {
        images.remove(atOffsets: offsets)
    }
    
    private func savePost() {
        // 根据列表类型生成新的 ID
        // 推荐列表范围：1000-1999
        // 热门列表范围：2000-2999
        let (minId, maxId, defaultId, fileName) = listType.getIdRange()
        
        let descriptor = FetchDescriptor<Post>(
            predicate: #Predicate<Post> { post in
                post.id >= minId && post.id < maxId
            },
            sortBy: [SortDescriptor(\.id, order: .reverse)]
        )
        let existingPosts = try? modelContext.fetch(descriptor)
        let maxExistingId = existingPosts?.first?.id ?? defaultId
        let newId = maxExistingId + 1
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let dateString = dateFormatter.string(from: Date())
        
        let newPost = Post(
            id: newId,
            avatar: avatar.isEmpty ? "default_avatar.jpg" : avatar,
            vip: false,
            name: name,
            date: dateString,
            isFollowed: false,
            text: text,
            images: images,
            commentCount: 0,
            likeCount: 0,
            isLiked: false,
            videoUrl: videoUrl
        )
        
        modelContext.insert(newPost)
        
        // 保存到 SwiftData
        do {
            try modelContext.save()
            print("✅ 新帖子已保存到\(listType == .recommend ? "推荐" : "热门")列表，ID: \(newId)")
        } catch {
            print("❌ 保存失败: \(error)")
        }
        
        // 同步到对应的 JSON 文件
        JSONService.savePostsToJSON(fileName: fileName, modelContext: modelContext)
        
        dismiss()
    }
}

/// 帖子列表类型枚举
enum PostListType {
    case recommend  // 推荐列表
    case hot        // 热门列表
    
    /// 获取ID范围和对应的JSON文件名
    /// - Returns: (最小ID, 最大ID, 默认ID, JSON文件名)
    func getIdRange() -> (Int, Int, Int, String) {
        switch self {
        case .recommend:
            return (1000, 2000, 999, "PostListData_recommend_2.json")
        case .hot:
            return (2000, 3000, 1999, "PostListData_hot_2.json")
        }
    }
}
