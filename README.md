# 新微博 Demo

一个基于 SwiftUI 和 SwiftData 构建的仿微博社交媒体应用，展示了现代 iOS 开发的最佳实践。

## 📱 功能特性

### 核心功能

- **双 Feed 流切换**：支持"推荐"和"热门"两个内容流，可通过顶部导航栏或滑动手势切换
- **帖子浏览**：展示包含文字、图片（最多9张）和视频的社交媒体帖子
- **下拉刷新 & 上拉加载**：流畅的列表刷新和分页加载体验
- **帖子详情**：点击帖子进入详情页，查看完整内容和评论
- **发布帖子**：支持发布文字、图片或视频内容
- **互动功能**：点赞、评论、转发、关注等社交互动
- **用户认证**：完整的登录/注册系统，支持 Token 管理和自动登录
- **本地存储**：使用 SwiftData 持久化数据，支持离线浏览

### 媒体功能

- **图片浏览器**：集成 JXPhotoBrowser，支持图片缩放、滑动浏览
- **视频播放**：内置视频播放器，支持本地和网络视频
- **图片选择器**：使用 PhotosPicker 选择相册图片和视频
- **媒体管理**：自动保存和管理本地媒体文件

## 🏗️ 技术架构

### 核心技术栈

- **SwiftUI**：声明式 UI 框架，构建现代化界面
- **SwiftData**：Apple 最新的数据持久化框架
- **Combine**：响应式编程，处理异步事件流
- **PhotosUI**：系统相册访问和媒体选择

### 第三方依赖

通过 CocoaPods 管理：

```ruby
pod 'JXPhotoBrowser'        # 图片浏览器
pod 'Alamofire'             # 网络请求（预留）
pod 'BBSwiftUIKit'          # SwiftUI 扩展组件
pod 'SDWebImageSwiftUI'     # 网络图片加载
pod 'KeychainSwift'         # Keychain 安全存储
```

## 📂 项目结构

```
newTestSwiftData/
├── Models/                 # 数据模型
│   ├── Post.swift         # 帖子模型（SwiftData）
│   ├── User.swift         # 用户模型
│   ├── Token.swift        # Token 模型
│   └── AuthModels.swift   # 认证相关模型
│
├── Views/                  # 视图层
│   ├── HomeView.swift     # 主页（双 Feed 流）
│   ├── PostListView.swift # 帖子列表
│   ├── PostCellView.swift # 帖子单元格
│   ├── PostDetailView.swift # 帖子详情
│   ├── AddPostView.swift  # 发布帖子
│   ├── LoginView.swift    # 登录页面
│   ├── RegisterView.swift # 注册页面
│   └── ...                # 其他视图组件
│
├── Services/               # 业务逻辑层
│   ├── AuthManager.swift  # 认证管理器
│   ├── UserData.swift     # 用户数据管理
│   ├── DataLoadManager.swift # 数据加载管理
│   ├── MediaManager.swift # 媒体文件管理
│   ├── KeychainManager.swift # Keychain 管理
│   ├── JSONService.swift  # JSON 数据服务
│   ├── MockAuthService.swift # Mock 认证服务
│   ├── MockPostAPIService.swift # Mock API 服务
│   └── SwiftDataAuthService.swift # SwiftData 认证服务
│
└── Resources/              # 资源文件
    ├── PostListData_recommend_1.json # 推荐数据
    ├── PostListData_recommend_2.json
    ├── PostListData_hot_1.json       # 热门数据
    └── PostListData_hot_2.json
```

## 🔧 实现方法

### 1. 数据持久化（SwiftData）

使用 SwiftData 作为主要的数据持久化方案：

```swift
@Model
final class Post {
    @Attribute(.unique) var id: Int
    var avatar: String
    var vip: Bool
    var name: String
    var date: String
    var text: String
    var images: [String]
    var commentCount: Int
    var likeCount: Int
    var isLiked: Bool
    var videoUrl: String
    // ...
}
```

**特点**：
- 使用 `@Model` 宏自动生成持久化代码
- 支持数组、可选值等复杂类型
- 通过 `@Attribute(.unique)` 确保 ID 唯一性
- 图片和视频存储为文件路径，节省数据库空间

### 2. 双数据库架构

项目采用双数据库设计，分离业务数据和认证数据：

- **主数据库**：存储帖子数据（Post）
- **认证数据库**：存储用户和 Token 数据（User、Token）

```swift
// 主数据库
var sharedModelContainer: ModelContainer = {
    let schema = Schema([Post.self])
    // ...
}()

// 认证数据库（独立）
class SwiftDataAuthService {
    private let authContainer: ModelContainer
    // ...
}
```

### 3. 混合数据源策略

结合 JSON 文件和 SwiftData，实现灵活的数据管理：

- **初始数据**：从 JSON 文件加载预置内容
- **用户数据**：保存到 SwiftData 和 JSON
- **数据同步**：双向同步确保数据一致性

```swift
// 从 JSON 加载
JSONService.loadPostsFromJSON(fileName: "PostListData_recommend_1.json")

// 保存到 JSON
JSONService.savePostsToJSON(fileName: "PostListData_recommend_2.json")
```

### 4. 认证系统

完整的用户认证流程：

**Token 管理**：
- **Access Token**：短期有效，存储在内存中
- **Refresh Token**：长期有效，加密存储在 Keychain

**自动登录**：
```swift
// App 启动时检查 Refresh Token
private func checkLoginState() {
    if let refreshToken = KeychainManager.shared.getRefreshToken() {
        if let tokenInfo = SwiftDataAuthService.shared.validateToken(refreshToken) {
            // 自动登录成功
            self.isLoggedIn = true
        }
    }
}
```

**Token 刷新**：
```swift
func refreshAccessToken(completion: @escaping (Bool) -> Void) {
    SwiftDataAuthService.shared.refreshToken(refreshToken) { result in
        // 刷新 Access Token
    }
}
```

### 5. Mock API 服务

模拟真实的网络请求流程，便于开发和测试：

```swift
class MockPostAPIService {
    func createPost(request: CreatePostRequest, 
                   accessToken: String?,
                   completion: @escaping (MockAPIResult<CreatePostResponse>) -> Void) {
        // 模拟网络延迟
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
            // 验证 Token
            // 生成响应
            // 返回结果
        }
    }
}
```

### 6. 媒体管理

统一管理图片和视频文件：

```swift
class MediaManager {
    // 保存图片
    func saveImage(data: Data) -> String?
    
    // 保存视频
    func saveVideo(data: Data) -> String?
    
    // 生成视频缩略图
    func generateVideoThumbnail(relativePath: String) -> UIImage?
    
    // 删除媒体文件
    func deleteMedia(relativePath: String)
}
```

**存储策略**：
- 文件保存在 `Documents/Media/` 目录
- 数据库只存储相对路径
- 自动生成唯一文件名（UUID）

### 7. 下拉刷新 & 上拉加载

使用 BBSwiftUIKit 实现流畅的列表交互：

```swift
BBTableView(posts) { post in
    PostCellView(post: post)
}
.bb_pullDownToRefresh(isRefreshing: $isRefreshing) {
    // 刷新数据
    userData.refreshPostlist(for: category)
}
.bb_pullUpToLoadMore(bottomSpace: 100) {
    // 加载更多
    userData.loadMorePostList(for: category)
}
```

### 8. 图片浏览器

集成 JXPhotoBrowser 实现专业的图片浏览体验：

```swift
struct PhotoBrowserWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> JXPhotoBrowser {
        let browser = JXPhotoBrowser()
        browser.numberOfItems = { self.images.count }
        browser.cellClassAtIndex = { _ in JXPhotoBrowserImageCell.self }
        // 配置数据源和代理
        return browser
    }
}
```

### 9. 视频播放

使用 AVPlayer 实现视频播放功能：

```swift
struct PostVideoPlayer: View {
    @State private var player: AVPlayer?
    
    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                player = AVPlayer(url: videoURL)
            }
    }
}
```

### 10. 状态管理

使用 `@Observable` 和 `@ObservableObject` 管理应用状态：

```swift
@Observable
class UserData {
    var recommendPosts: [Post] = []
    var hotPosts: [Post] = []
    var isRefreshing = false
    var isLoadingMore = false
    
    func refreshPostlist(for category: PostListCategory) {
        // 刷新逻辑
    }
}
```

## 🚀 运行项目

### 环境要求

- Xcode 15.0+
- iOS 17.0+
- CocoaPods 1.12+

### 安装步骤

1. **克隆项目**
```bash
git clone <repository-url>
cd newWeiboDemo
```

2. **安装依赖**
```bash
pod install
```

3. **打开工作空间**
```bash
open newTestSwiftData.xcworkspace
```

4. **运行项目**
- 选择模拟器或真机
- 点击 Run (⌘R)

## 📝 测试账号

项目内置测试账号，可直接登录：

- 用户名：`testuser`
- 密码：`password123`

或者注册新账号进行测试。

## 🎯 核心亮点

1. **现代化架构**：采用 SwiftUI + SwiftData 最新技术栈
2. **双数据库设计**：业务数据与认证数据分离，提高安全性
3. **混合数据源**：JSON + SwiftData，灵活高效
4. **完整认证流程**：Token 管理、自动登录、安全存储
5. **Mock API**：模拟真实网络请求，便于开发测试
6. **流畅交互**：下拉刷新、上拉加载、动画过渡
7. **媒体支持**：图片、视频上传和浏览
8. **代码规范**：清晰的项目结构，详细的注释

## 📚 学习要点

通过这个项目，你可以学习到：

- ✅ SwiftData 的使用和最佳实践
- ✅ SwiftUI 的声明式编程思想
- ✅ MVVM 架构模式
- ✅ Combine 响应式编程
- ✅ Keychain 安全存储
- ✅ 文件系统操作
- ✅ 图片和视频处理
- ✅ 第三方库集成
- ✅ Mock 数据和 API 设计
- ✅ 用户认证和授权

## 🔮 未来计划

- [ ] 接入真实后端 API
- [ ] 实现消息通知
- [ ] 支持深色模式优化
- [ ] 添加更多社交功能
- [ ] 性能优化和缓存策略

## 📄 许可证

本项目仅用于学习和演示目的。

## 👨‍💻 作者

Created by cjx - 2026

---

**注意**：本项目是一个学习项目，展示了 iOS 开发的各种技术和最佳实践。代码中包含详细注释，适合初学者学习参考。

