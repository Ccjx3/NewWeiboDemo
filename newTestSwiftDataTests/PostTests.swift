//
//  PostTests.swift
//  newTestSwiftDataTests
//
//  Created by Unit Test Suite
//

import XCTest
import SwiftData
@testable import newTestSwiftData

/// Post 模型单元测试
final class PostTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    // MARK: - 测试生命周期
    
    override func setUp() {
        super.setUp()
        
        let schema = Schema([Post.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
            modelContext = ModelContext(modelContainer)
        } catch {
            fatalError("无法创建测试用 ModelContainer: \(error)")
        }
    }
    
    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        super.tearDown()
    }
    
    // MARK: - 帖子创建测试
    
    /// 测试：创建普通帖子
    func testCreatePost() {
        // Given & When
        let post = Post(
            id: 1000,
            avatar: "avatar1.jpg",
            vip: false,
            name: "测试用户",
            date: "2026-02-01 10:00",
            isFollowed: false,
            text: "这是一条测试帖子",
            images: ["image1.jpg", "image2.jpg"],
            commentCount: 10,
            likeCount: 100,
            isLiked: false
        )
        
        // Then
        XCTAssertEqual(post.id, 1000)
        XCTAssertEqual(post.name, "测试用户")
        XCTAssertEqual(post.images.count, 2)
        XCTAssertFalse(post.hasVideo)
    }
    
    /// 测试：创建视频帖子
    func testCreateVideoPost() {
        // Given & When
        let post = Post(
            id: 3000,
            avatar: "avatar1.jpg",
            vip: true,
            name: "VIP用户",
            date: "2026-02-01 10:00",
            isFollowed: true,
            text: "这是一条视频帖子",
            images: [],
            commentCount: 50,
            likeCount: 500,
            isLiked: true,
            videoUrl: "video1.mp4"
        )
        
        // Then
        XCTAssertTrue(post.hasVideo)
        XCTAssertEqual(post.videoUrl, "video1.mp4")
        XCTAssertTrue(post.vip)
    }
    
    // MARK: - JSON 转换测试
    
    /// 测试：从 JSON 创建帖子
    func testCreatePostFromJSON() {
        // Given
        let json: [String: Any] = [
            "id": 1000,
            "avatar": "avatar1.jpg",
            "vip": false,
            "name": "测试用户",
            "date": "2026-02-01 10:00",
            "isFollowed": false,
            "text": "测试内容",
            "images": ["image1.jpg"],
            "commentCount": 10,
            "likeCount": 100,
            "isLiked": false,
            "video_url": ""
        ]
        
        // When
        let post = Post(from: json)
        
        // Then
        XCTAssertNotNil(post)
        XCTAssertEqual(post?.id, 1000)
        XCTAssertEqual(post?.name, "测试用户")
    }
    
    /// 测试：转换为 JSON
    func testConvertPostToJSON() {
        // Given
        let post = Post(
            id: 1000,
            avatar: "avatar1.jpg",
            vip: false,
            name: "测试用户",
            date: "2026-02-01 10:00",
            isFollowed: false,
            text: "测试内容",
            images: ["image1.jpg"],
            commentCount: 10,
            likeCount: 100,
            isLiked: false
        )
        
        // When
        let json = post.toJSON()
        
        // Then
        XCTAssertEqual(json["id"] as? Int, 1000)
        XCTAssertEqual(json["name"] as? String, "测试用户")
        XCTAssertEqual(json["commentCount"] as? Int, 10)
    }
    
    // MARK: - 数据源类型测试
    
    /// 测试：本地帖子判断
    func testIsLocalPost() {
        // Given
        let localPost = Post(
            id: 10000,
            avatar: "avatar1.jpg",
            vip: false,
            name: "本地用户",
            date: "2026-02-01 10:00",
            isFollowed: false,
            text: "本地帖子",
            images: [],
            commentCount: 0,
            likeCount: 0,
            isLiked: false
        )
        
        let networkPost = Post(
            id: 1000,
            avatar: "avatar1.jpg",
            vip: false,
            name: "网络用户",
            date: "2026-02-01 10:00",
            isFollowed: false,
            text: "网络帖子",
            images: [],
            commentCount: 0,
            likeCount: 0,
            isLiked: false
        )
        
        // Then
        XCTAssertTrue(localPost.isLocalPost)
        XCTAssertFalse(networkPost.isLocalPost)
    }
    
    /// 测试：数据源类型识别
    func testSourceType() {
        // Given
        let recommendPost = Post(id: 1000, avatar: "", vip: false, name: "", date: "", isFollowed: false, text: "", images: [], commentCount: 0, likeCount: 0, isLiked: false)
        let hotPost = Post(id: 2000, avatar: "", vip: false, name: "", date: "", isFollowed: false, text: "", images: [], commentCount: 0, likeCount: 0, isLiked: false)
        let videoPost = Post(id: 3000, avatar: "", vip: false, name: "", date: "", isFollowed: false, text: "", images: [], commentCount: 0, likeCount: 0, isLiked: false)
        let userPost = Post(id: 10000, avatar: "", vip: false, name: "", date: "", isFollowed: false, text: "", images: [], commentCount: 0, likeCount: 0, isLiked: false)
        
        // Then
        XCTAssertEqual(recommendPost.sourceType, .recommendNetwork)
        XCTAssertEqual(hotPost.sourceType, .hotNetwork)
        XCTAssertEqual(videoPost.sourceType, .videoNetwork)
        XCTAssertEqual(userPost.sourceType, .userLocal)
    }
    
    // MARK: - SwiftData 持久化测试
    
    /// 测试：保存帖子到 SwiftData
    func testSavePostToSwiftData() throws {
        // Given
        let post = Post(
            id: 1000,
            avatar: "avatar1.jpg",
            vip: false,
            name: "测试用户",
            date: "2026-02-01 10:00",
            isFollowed: false,
            text: "测试内容",
            images: ["image1.jpg"],
            commentCount: 10,
            likeCount: 100,
            isLiked: false
        )
        
        // When
        modelContext.insert(post)
        try modelContext.save()
        
        // Then
        let descriptor = FetchDescriptor<Post>()
        let posts = try modelContext.fetch(descriptor)
        XCTAssertEqual(posts.count, 1)
        XCTAssertEqual(posts.first?.id, 1000)
    }
    
    /// 测试：查询帖子
    func testFetchPostById() throws {
        // Given
        let post = Post(
            id: 1000,
            avatar: "avatar1.jpg",
            vip: false,
            name: "测试用户",
            date: "2026-02-01 10:00",
            isFollowed: false,
            text: "测试内容",
            images: [],
            commentCount: 10,
            likeCount: 100,
            isLiked: false
        )
        modelContext.insert(post)
        try modelContext.save()
        
        // When
        let postId = 1000
        let predicate = #Predicate<Post> { p in
            p.id == postId
        }
        let descriptor = FetchDescriptor<Post>(predicate: predicate)
        let fetchedPosts = try modelContext.fetch(descriptor)
        
        // Then
        XCTAssertEqual(fetchedPosts.count, 1)
        XCTAssertEqual(fetchedPosts.first?.name, "测试用户")
    }
    
    /// 测试：批量保存帖子
    func testBatchSavePosts() throws {
        // Given
        let posts = (1...10).map { i in
            Post(
                id: 1000 + i,
                avatar: "avatar\(i).jpg",
                vip: false,
                name: "用户\(i)",
                date: "2026-02-01 10:00",
                isFollowed: false,
                text: "内容\(i)",
                images: [],
                commentCount: i,
                likeCount: i * 10,
                isLiked: false
            )
        }
        
        // When
        for post in posts {
            modelContext.insert(post)
        }
        try modelContext.save()
        
        // Then
        let descriptor = FetchDescriptor<Post>()
        let savedPosts = try modelContext.fetch(descriptor)
        XCTAssertEqual(savedPosts.count, 10)
    }
}

