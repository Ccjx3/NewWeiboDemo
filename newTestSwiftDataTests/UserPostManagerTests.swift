//
//  UserPostManagerTests.swift
//  newTestSwiftDataTests
//
//  Created by Unit Test Suite
//

import XCTest
import SwiftData
@testable import newTestSwiftData

/// UserPostManager 单元测试
final class UserPostManagerTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var userPostManager: UserPostManager!
    
    // MARK: - 测试生命周期
    
    override func setUp() {
        super.setUp()
        
        let schema = Schema([Post.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
            modelContext = ModelContext(modelContainer)
            userPostManager = UserPostManager.shared
        } catch {
            fatalError("无法创建测试用 ModelContainer: \(error)")
        }
    }
    
    override func tearDown() {
        // 清理测试数据
        userPostManager.clearAllUserPosts()
        modelContainer = nil
        modelContext = nil
        userPostManager = nil
        super.tearDown()
    }
    
    // MARK: - ID 生成测试
    
    /// 测试：生成新的用户帖子 ID
    func testGenerateNewUserPostID() {
        // When
        let id1 = userPostManager.generateNewUserPostID(modelContext: modelContext)
        let id2 = userPostManager.generateNewUserPostID(modelContext: modelContext)
        
        // Then
        XCTAssertGreaterThanOrEqual(id1, 10000, "用户帖子 ID 应该从 10000 开始")
        XCTAssertEqual(id1, id2, "没有插入新帖子时，ID 应该相同")
    }
    
    /// 测试：插入帖子后 ID 递增
    func testIDIncrementAfterInsert() throws {
        // Given
        let id1 = userPostManager.generateNewUserPostID(modelContext: modelContext)
        let post = Post(
            id: id1,
            avatar: "avatar.jpg",
            vip: false,
            name: "测试用户",
            date: "2026-02-01",
            isFollowed: false,
            text: "测试内容",
            images: [],
            commentCount: 0,
            likeCount: 0,
            isLiked: false
        )
        modelContext.insert(post)
        try modelContext.save()
        
        // When
        let id2 = userPostManager.generateNewUserPostID(modelContext: modelContext)
        
        // Then
        XCTAssertEqual(id2, id1 + 1, "插入帖子后，新 ID 应该递增")
    }
    
    // MARK: - 保存帖子测试
    
    /// 测试：保存单个用户帖子
    func testSaveUserPost() {
        // Given
        let post = Post(
            id: 10001,
            avatar: "avatar.jpg",
            vip: false,
            name: "测试用户",
            date: "2026-02-01",
            isFollowed: false,
            text: "测试内容",
            images: [],
            commentCount: 0,
            likeCount: 0,
            isLiked: false
        )
        
        // When
        let result = userPostManager.saveUserPost(post, modelContext: modelContext)
        
        // Then
        XCTAssertTrue(result, "保存应该成功")
        
        let loadedPosts = userPostManager.loadUserPosts()
        XCTAssertEqual(loadedPosts.count, 1)
        XCTAssertEqual(loadedPosts.first?.id, 10001)
    }
    
    /// 测试：更新已存在的帖子
    func testUpdateExistingPost() {
        // Given
        let post1 = Post(
            id: 10001,
            avatar: "avatar.jpg",
            vip: false,
            name: "原始用户",
            date: "2026-02-01",
            isFollowed: false,
            text: "原始内容",
            images: [],
            commentCount: 0,
            likeCount: 0,
            isLiked: false
        )
        userPostManager.saveUserPost(post1, modelContext: modelContext)
        
        let post2 = Post(
            id: 10001,
            avatar: "avatar.jpg",
            vip: false,
            name: "更新用户",
            date: "2026-02-01",
            isFollowed: false,
            text: "更新内容",
            images: [],
            commentCount: 10,
            likeCount: 100,
            isLiked: true
        )
        
        // When
        userPostManager.saveUserPost(post2, modelContext: modelContext)
        
        // Then
        let loadedPosts = userPostManager.loadUserPosts()
        XCTAssertEqual(loadedPosts.count, 1, "应该只有一条帖子")
        XCTAssertEqual(loadedPosts.first?.name, "更新用户")
        XCTAssertEqual(loadedPosts.first?.text, "更新内容")
    }
    
    /// 测试：批量保存帖子
    func testBatchSavePosts() {
        // Given
        let posts = (1...5).map { i in
            Post(
                id: 10000 + i,
                avatar: "avatar\(i).jpg",
                vip: false,
                name: "用户\(i)",
                date: "2026-02-01",
                isFollowed: false,
                text: "内容\(i)",
                images: [],
                commentCount: i,
                likeCount: i * 10,
                isLiked: false
            )
        }
        
        // When
        let result = userPostManager.saveUserPosts(posts, modelContext: modelContext)
        
        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(userPostManager.getUserPostCount(), 5)
    }
    
    // MARK: - 加载帖子测试
    
    /// 测试：加载空数据
    func testLoadEmptyPosts() {
        // When
        let posts = userPostManager.loadUserPosts()
        
        // Then
        XCTAssertEqual(posts.count, 0)
    }
    
    /// 测试：加载已保存的帖子
    func testLoadSavedPosts() {
        // Given
        let post = Post(
            id: 10001,
            avatar: "avatar.jpg",
            vip: false,
            name: "测试用户",
            date: "2026-02-01",
            isFollowed: false,
            text: "测试内容",
            images: ["image1.jpg"],
            commentCount: 10,
            likeCount: 100,
            isLiked: false
        )
        userPostManager.saveUserPost(post, modelContext: modelContext)
        
        // When
        let loadedPosts = userPostManager.loadUserPosts()
        
        // Then
        XCTAssertEqual(loadedPosts.count, 1)
        XCTAssertEqual(loadedPosts.first?.id, 10001)
        XCTAssertEqual(loadedPosts.first?.name, "测试用户")
        XCTAssertEqual(loadedPosts.first?.images.count, 1)
    }
    
    // MARK: - 删除帖子测试
    
    /// 测试：删除存在的帖子
    func testDeleteExistingPost() {
        // Given
        let post = Post(
            id: 10001,
            avatar: "avatar.jpg",
            vip: false,
            name: "测试用户",
            date: "2026-02-01",
            isFollowed: false,
            text: "测试内容",
            images: [],
            commentCount: 0,
            likeCount: 0,
            isLiked: false
        )
        userPostManager.saveUserPost(post, modelContext: modelContext)
        
        // When
        let result = userPostManager.deleteUserPost(postId: 10001, modelContext: modelContext)
        
        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(userPostManager.getUserPostCount(), 0)
    }
    
    /// 测试：删除不存在的帖子
    func testDeleteNonExistentPost() {
        // When
        let result = userPostManager.deleteUserPost(postId: 99999, modelContext: modelContext)
        
        // Then
        XCTAssertFalse(result, "删除不存在的帖子应该返回 false")
    }
    
    // MARK: - 工具方法测试
    
    /// 测试：获取用户帖子总数
    func testGetUserPostCount() {
        // Given
        let posts = (1...3).map { i in
            Post(
                id: 10000 + i,
                avatar: "avatar.jpg",
                vip: false,
                name: "用户\(i)",
                date: "2026-02-01",
                isFollowed: false,
                text: "内容\(i)",
                images: [],
                commentCount: 0,
                likeCount: 0,
                isLiked: false
            )
        }
        userPostManager.saveUserPosts(posts, modelContext: modelContext)
        
        // When
        let count = userPostManager.getUserPostCount()
        
        // Then
        XCTAssertEqual(count, 3)
    }
    
    /// 测试：清空所有用户帖子
    func testClearAllUserPosts() {
        // Given
        let posts = (1...3).map { i in
            Post(
                id: 10000 + i,
                avatar: "avatar.jpg",
                vip: false,
                name: "用户\(i)",
                date: "2026-02-01",
                isFollowed: false,
                text: "内容\(i)",
                images: [],
                commentCount: 0,
                likeCount: 0,
                isLiked: false
            )
        }
        userPostManager.saveUserPosts(posts, modelContext: modelContext)
        
        // When
        let result = userPostManager.clearAllUserPosts()
        
        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(userPostManager.getUserPostCount(), 0)
    }
    
    /// 测试：导出用户帖子 JSON
    func testExportUserPostsJSON() {
        // Given
        let post = Post(
            id: 10001,
            avatar: "avatar.jpg",
            vip: false,
            name: "测试用户",
            date: "2026-02-01",
            isFollowed: false,
            text: "测试内容",
            images: [],
            commentCount: 0,
            likeCount: 0,
            isLiked: false
        )
        userPostManager.saveUserPost(post, modelContext: modelContext)
        
        // When
        let jsonString = userPostManager.exportUserPostsJSON()
        
        // Then
        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString!.contains("10001"))
        XCTAssertTrue(jsonString!.contains("测试用户"))
    }
}

