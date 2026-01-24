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
    
    @State private var name = ""
    @State private var text = ""
    @State private var avatar = ""
    @State private var images: [String] = []
    @State private var newImageName = ""
    
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
        // 生成新的 ID（使用当前最大的 ID + 1）
        let descriptor = FetchDescriptor<Post>(sortBy: [SortDescriptor(\.id, order: .reverse)])
        let existingPosts = try? modelContext.fetch(descriptor)
        let newId = (existingPosts?.first?.id ?? 0) + 1
        
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
            isLiked: false
        )
        
        modelContext.insert(newPost)
        
        // 保存到 SwiftData
        try? modelContext.save()
        
        // 同步到 JSON 文件
        JSONService.savePostsToJSON(fileName: "PostListData_recommend_1.json", modelContext: modelContext)
        
        dismiss()
    }
}
