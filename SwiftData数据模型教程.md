# SwiftData 数据模型构建教程

## 📚 目录

1. [SwiftData 简介](#swiftdata-简介)
2. [数据模型设计](#数据模型设计)
3. [图片存储方案](#图片存储方案)
4. [完整实现步骤](#完整实现步骤)
5. [常见问题解答](#常见问题解答)

---

## SwiftData 简介

### 什么是 SwiftData？

SwiftData 是 Apple 在 iOS 17+ 推出的现代数据持久化框架，它：
- 基于 Swift 宏系统（Macros）
- 简化了 Core Data 的复杂性
- 与 SwiftUI 深度集成
- 支持类型安全的查询

### 为什么使用 SwiftData？

1. **简单易用**: 只需 `@Model` 宏即可定义模型
2. **类型安全**: 编译时检查，减少运行时错误
3. **自动同步**: 与 SwiftUI 自动同步，无需手动刷新
4. **性能优秀**: 底层基于 Core Data，性能可靠

---

## 数据模型设计

### 1. 分析 JSON 结构

首先，我们需要分析 JSON 文件的结构：

```json
{
    "list": [
        {
            "id": 1000,
            "avatar": "4e7f0c83ly8g1ho507078j20ro0rojtq.jpg",
            "vip": true,
            "name": "娄艺潇",
            "date": "2020-01-05 22:51",
            "isFollowed": false,
            "text": "潮汕菜太好吃了...",
            "images": ["image1.jpg", "image2.jpg"],
            "commentCount": 2200,
            "likeCount": 11319,
            "isLiked": true
        }
    ]
}
```

### 2. 设计 SwiftData 模型

#### 步骤 1: 导入必要的框架

```swift
import Foundation
import SwiftData
```

#### 步骤 2: 使用 @Model 宏定义模型

```swift
@Model
final class Post {
    // 属性定义
}
```

**为什么使用 `final class`？**
- `final` 防止类被继承，提高性能
- SwiftData 要求模型类不能被继承

#### 步骤 3: 定义属性

根据 JSON 结构，定义对应的属性：

```swift
@Model
final class Post {
    var id: Int              // 帖子 ID
    var avatar: String       // 头像文件名
    var vip: Bool           // 是否 VIP
    var name: String        // 用户名
    var date: String        // 发布日期
    var isFollowed: Bool    // 是否关注
    var text: String        // 文本内容
    var images: [String]    // 图片文件名数组
    var commentCount: Int   // 评论数
    var likeCount: Int      // 点赞数
    var isLiked: Bool       // 是否点赞
}
```

**属性类型说明**:
- `Int`, `String`, `Bool`: SwiftData 原生支持
- `[String]`: 数组类型，SwiftData 自动支持
- 所有属性必须是 `var`，不能是 `let`

#### 步骤 4: 添加初始化方法

```swift
init(
    id: Int,
    avatar: String,
    vip: Bool,
    name: String,
    date: String,
    isFollowed: Bool,
    text: String,
    images: [String],
    commentCount: Int,
    likeCount: Int,
    isLiked: Bool
) {
    self.id = id
    self.avatar = avatar
    // ... 其他属性赋值
}
```

#### 步骤 5: 添加 JSON 转换方法

**从 JSON 创建模型**:
```swift
convenience init?(from json: [String: Any]) {
    guard let id = json["id"] as? Int,
          let avatar = json["avatar"] as? String,
          // ... 其他字段检查
    else {
        return nil  // 数据不完整，返回 nil
    }
    
    self.init(
        id: id,
        avatar: avatar,
        // ... 其他参数
    )
}
```

**转换为 JSON**:
```swift
func toJSON() -> [String: Any] {
    return [
        "id": id,
        "avatar": avatar,
        // ... 其他字段
    ]
}
```

#### 步骤 6: 实现 Identifiable 协议

```swift
extension Post: Identifiable {}
```

**为什么需要 Identifiable？**
- SwiftUI 的 `ForEach` 需要 `Identifiable`
- `id` 属性自动满足协议要求

---

## 图片存储方案

### SwiftData 中图片的存储方式详解

#### 方案对比

| 方案 | 存储类型 | 优点 | 缺点 | 适用场景 |
|------|---------|------|------|----------|
| **文件名** | `String` | 数据库小、查询快、支持异步 | 需管理文件 | ✅ **推荐** |
| **二进制** | `Data` | 数据完整 | 数据库大、加载慢 | 小图片、必须内嵌 |
| **URL** | `URL` | 支持远程 | 需网络、需缓存 | 网络图片 |

### 方案 1: 存储文件名（本项目采用）

```swift
var avatar: String       // "avatar.jpg"
var images: [String]     // ["img1.jpg", "img2.jpg"]
```

**实现原理**:
1. 数据库只存储文件名字符串
2. 图片文件放在 Resources 文件夹
3. 显示时通过文件名加载图片

**加载图片代码**:
```swift
func imageURL(for fileName: String) -> URL? {
    return Bundle.main.url(
        forResource: fileName,
        withExtension: nil,
        subdirectory: "Resources"
    )
}

// 使用
AsyncImage(url: imageURL(for: post.avatar)) { image in
    image.resizable()
} placeholder: {
    ProgressView()
}
```

**为什么选择这个方案？**
1. ✅ JSON 文件中就是文件名
2. ✅ 数据库体积小（文件名通常 < 100 字节）
3. ✅ 查询速度快（字符串比较）
4. ✅ 支持异步加载（不阻塞 UI）
5. ✅ 便于资源管理（图片在 Resources 文件夹）

### 方案 2: 存储二进制数据

```swift
@Attribute(.externalStorage) var avatarData: Data?
```

**@Attribute(.externalStorage) 说明**:
- SwiftData 会将大数据存储在外部文件
- 数据库只存储引用
- 适合较大的二进制数据

**使用场景**:
- 图片必须内嵌在数据库中
- 图片数量少且体积小
- 不需要外部文件管理

### 方案 3: 存储 URL

```swift
var imageURL: URL?
```

**使用场景**:
- 网络图片
- 需要支持远程加载
- 需要实现缓存机制

---

## 完整实现步骤

### 步骤 1: 创建数据模型文件

1. 在 Xcode 中创建新文件：`Post.swift`
2. 放在 `Models` 文件夹（如果没有则创建）
3. 复制完整的模型代码

### 步骤 2: 配置 ModelContainer

在 `App` 文件中：

```swift
import SwiftUI
import SwiftData

@main
struct newTestSwiftDataApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Post.self,  // 注册 Post 模型
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false  // 持久化存储
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("无法创建 ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)  // 注入容器
    }
}
```

**关键点**:
- `Schema([Post.self])`: 注册所有模型
- `isStoredInMemoryOnly: false`: 持久化到磁盘
- `.modelContainer()`: 注入到视图层次

### 步骤 3: 创建 JSON 服务

1. 创建 `Services/JSONService.swift`
2. 实现加载和保存方法

**加载 JSON 到 SwiftData**:
```swift
static func loadPostsFromJSON(
    fileName: String,
    modelContext: ModelContext
) -> [Post] {
    // 1. 从 Bundle 读取 JSON 文件
    guard let url = Bundle.main.url(
        forResource: fileName,
        withExtension: nil,
        subdirectory: "Resources"
    ) else {
        return []
    }
    
    // 2. 解析 JSON
    let data = try Data(contentsOf: url)
    let json = try JSONSerialization.jsonObject(with: data)
    
    // 3. 转换为 Post 对象
    guard let list = json["list"] as? [[String: Any]] else {
        return []
    }
    
    var posts: [Post] = []
    for item in list {
        if let post = Post(from: item) {
            // 4. 检查是否已存在（避免重复）
            let descriptor = FetchDescriptor<Post>(
                predicate: #Predicate { $0.id == post.id }
            )
            let existing = try? modelContext.fetch(descriptor)
            
            if existing?.isEmpty ?? true {
                modelContext.insert(post)  // 5. 插入到 SwiftData
                posts.append(post)
            }
        }
    }
    
    // 6. 保存
    try? modelContext.save()
    return posts
}
```

**保存 SwiftData 到 JSON**:
```swift
static func savePostsToJSON(
    fileName: String,
    modelContext: ModelContext
) -> Bool {
    // 1. 从 SwiftData 获取所有 Post
    let descriptor = FetchDescriptor<Post>(
        sortBy: [SortDescriptor(\.id)]
    )
    let posts = try? modelContext.fetch(descriptor)
    
    // 2. 转换为 JSON 数组
    let jsonArray = posts?.map { $0.toJSON() } ?? []
    let json: [String: Any] = ["list": jsonArray]
    
    // 3. 保存到 Documents 目录（可写）
    guard let documentsURL = FileManager.default.urls(
        for: .documentDirectory,
        in: .userDomainMask
    ).first else {
        return false
    }
    
    let fileURL = documentsURL.appendingPathComponent(fileName)
    let jsonData = try JSONSerialization.data(
        withJSONObject: json,
        options: [.prettyPrinted, .sortedKeys]
    )
    
    try? jsonData.write(to: fileURL)
    return true
}
```

### 步骤 4: 创建视图

#### 主列表视图

```swift
struct PostListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Post.id) private var posts: [Post]
    
    var body: some View {
        List {
            ForEach(posts) { post in
                PostCellView(post: post)
            }
        }
    }
}
```

**@Query 说明**:
- 自动查询 SwiftData 数据
- 数据变化时自动更新视图
- `sort` 参数指定排序方式

#### 单元格视图

```swift
struct PostCellView: View {
    @Bindable var post: Post  // @Bindable 支持双向绑定
    
    var body: some View {
        VStack {
            // 显示帖子内容
            Text(post.text)
            
            // 点赞按钮
            Button(action: {
                post.isLiked.toggle()
            }) {
                Image(systemName: post.isLiked ? "heart.fill" : "heart")
            }
        }
    }
}
```

**@Bindable 说明**:
- 允许视图修改模型属性
- 修改后需要调用 `modelContext.save()`

### 步骤 5: 初始化数据

在 `ContentView` 或 `App` 启动时：

```swift
.onAppear {
    // 检查是否已有数据
    let descriptor = FetchDescriptor<Post>()
    let existingPosts = try? modelContext.fetch(descriptor)
    
    if existingPosts?.isEmpty ?? true {
        // 首次启动，加载 JSON
        JSONService.loadPostsFromJSON(
            fileName: "PostListData_recommend_1.json",
            modelContext: modelContext
        )
    }
}
```

---

## 添加新帖子并同步

### 完整流程

#### 1. 创建添加视图

```swift
struct AddPostView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var text = ""
    // ... 其他字段
    
    var body: some View {
        NavigationView {
            Form {
                TextField("用户名", text: $name)
                TextEditor(text: $text)
                // ... 其他输入
            }
            .toolbar {
                Button("保存") {
                    savePost()
                }
            }
        }
    }
    
    private func savePost() {
        // 1. 生成新 ID
        let descriptor = FetchDescriptor<Post>(
            sortBy: [SortDescriptor(\.id, order: .reverse)]
        )
        let existingPosts = try? modelContext.fetch(descriptor)
        let newId = (existingPosts?.first?.id ?? 0) + 1
        
        // 2. 创建新 Post
        let newPost = Post(
            id: newId,
            avatar: "default_avatar.jpg",
            vip: false,
            name: name,
            date: DateFormatter().string(from: Date()),
            isFollowed: false,
            text: text,
            images: [],
            commentCount: 0,
            likeCount: 0,
            isLiked: false
        )
        
        // 3. 插入到 SwiftData
        modelContext.insert(newPost)
        try? modelContext.save()
        
        // 4. 同步到 JSON 文件
        JSONService.savePostsToJSON(
            fileName: "PostListData_recommend_1.json",
            modelContext: modelContext
        )
        
        // 5. 关闭视图
        dismiss()
    }
}
```

#### 2. 在主视图中调用

```swift
struct PostListView: View {
    @State private var showingAddPost = false
    
    var body: some View {
        List { ... }
            .toolbar {
                Button(action: {
                    showingAddPost = true
                }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingAddPost) {
                AddPostView()
            }
    }
}
```

#### 3. 自动同步机制

**方案 A: 实时同步（推荐用于小数据量）**
```swift
// 每次操作后立即同步
private func savePost() {
    modelContext.insert(newPost)
    try? modelContext.save()
    JSONService.savePostsToJSON(...)  // 立即同步
}
```

**方案 B: 批量同步（推荐用于大数据量）**
```swift
// 在视图消失时同步
.onDisappear {
    JSONService.savePostsToJSON(...)
}

// 或定时同步
Timer.publish(every: 30, on: .main, in: .common)
    .autoconnect()
    .sink { _ in
        JSONService.savePostsToJSON(...)
    }
```

#### 4. 视图自动更新

由于使用了 `@Query`，当数据变化时，视图会自动更新：

```swift
@Query(sort: \Post.id) private var posts: [Post]
// ↑ 这个查询会自动监听数据变化
// 当 modelContext.insert() 或 save() 后
// posts 数组会自动更新
// 视图会自动刷新
```

---

## 常见问题解答

### Q1: 为什么使用 `@Model` 而不是 Core Data？

**A**: 
- `@Model` 更简单，代码更少
- 类型安全，编译时检查
- 与 SwiftUI 深度集成
- 自动生成持久化代码

### Q2: 图片为什么不直接存 Data？

**A**:
- 数据库体积会急剧增大
- 查询和加载速度慢
- 不利于资源管理
- JSON 文件中就是文件名，保持一致

### Q3: Bundle 是只读的，怎么保存 JSON？

**A**:
- Bundle 中的文件是只读的
- 保存到 Documents 目录（可写）
- 如果需要更新 Bundle 中的文件，需要手动复制

### Q4: 如何实现数据迁移？

**A**:
```swift
let modelConfiguration = ModelConfiguration(
    schema: schema,
    isStoredInMemoryOnly: false,
    cloudKitDatabase: .automatic  // 可选：iCloud 同步
)
```

### Q5: @Query 会自动更新吗？

**A**: 
- 是的，当 SwiftData 中的数据变化时
- `@Query` 会自动重新查询
- 视图会自动刷新
- 无需手动调用刷新方法

### Q6: 如何实现搜索和筛选？

**A**:
```swift
@Query(
    filter: #Predicate<Post> { post in
        post.name.contains(searchText)
    },
    sort: \Post.id
) private var filteredPosts: [Post]
```

### Q7: 性能优化建议？

**A**:
1. 使用 `@Attribute(.externalStorage)` 存储大文件
2. 实现分页加载
3. 图片使用异步加载和缓存
4. 批量操作时使用 `modelContext.save()` 一次

---

## 📖 总结

通过本教程，你学会了：

1. ✅ 如何使用 `@Model` 定义 SwiftData 模型
2. ✅ 如何设计图片存储方案
3. ✅ 如何实现 JSON 和 SwiftData 的双向同步
4. ✅ 如何创建展示列表和添加功能
5. ✅ 如何实现自动同步机制

现在你可以开始构建自己的 SwiftData 应用了！🚀
