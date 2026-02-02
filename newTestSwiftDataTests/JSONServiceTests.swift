//
//  JSONServiceTests.swift
//  newTestSwiftDataTests
//
//  Created by Unit Test Suite
//

import XCTest
import SwiftData
@testable import newTestSwiftData

/// JSONService 单元测试
final class JSONServiceTests: XCTestCase {
    
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
    
    // MARK: - 加载 JSON 测试
    
    /// 测试：从 JSON 文件加载帖子
    func testLoadPostsFromJSON() {
        // Given
        let fileName = "PostListData_recommend_1.json"
        
        // When
        let posts = JSONService.loadPostsFromJSON(fileName: fileName, modelContext: modelContext)
        
        // Then
        XCTAssertGreaterThan(posts.count, 0, "应该加载到帖子数据")
    }
    
    /// 测试：加载不存在的 JSON 文件
    func testLoadNonExistentJSON() {
        // Given
        let fileName = "NonExistent.json"
        
        // When
        let posts = JSONService.loadPostsFromJSON(fileName: fileName, modelContext: modelContext)
        
        // Then
        XCTAssertEqual(posts.count, 0, "不存在的文件应该返回空数组")
    }
    
    /// 测试：重复加载相同的 JSON（测试去重）
    func testLoadDuplicateJSON() {
        // Given
        let fileName = "PostListData_recommend_1.json"
        
        // When
        let firstLoad = JSONService.loadPostsFromJSON(fileName: fileName, modelContext: modelContext)
        let secondLoad = JSONService.loadPostsFromJSON(fileName: fileName, modelContext: modelContext)
        
        // Then
        XCTAssertGreaterThan(firstLoad.count, 0)
        XCTAssertEqual(secondLoad.count, 0, "重复加载应该被跳过")
    }
    
    // MARK: - 保存 JSON 测试
    
    /// 测试：保存帖子到 JSON
    func testSavePostsToJSON() throws {
        // Given
        let posts = [
            Post(id: 1000, avatar: "avatar1.jpg", vip: false, name: "用户1", date: "2026-02-01", isFollowed: false, text: "内容1", images: [], commentCount: 10, likeCount: 100, isLiked: false),
            Post(id: 1001, avatar: "avatar2.jpg", vip: false, name: "用户2", date: "2026-02-01", isFollowed: false, text: "内容2", images: [], commentCount: 20, likeCount: 200, isLiked: false)
        ]
        
        for post in posts {
            modelContext.insert(post)
        }
        try modelContext.save()
        
        // When
        let fileName = "TestPosts.json"
        let result = JSONService.savePostsToJSON(fileName: fileName, modelContext: modelContext)
        
        // Then
        XCTAssertTrue(result, "保存应该成功")
        
        // 验证文件是否存在
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent(fileName)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        
        // 清理测试文件
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    /// 测试：保存空数据
    func testSaveEmptyPosts() {
        // Given
        // 没有插入任何帖子
        
        // When
        let fileName = "EmptyPosts.json"
        let result = JSONService.savePostsToJSON(fileName: fileName, modelContext: modelContext)
        
        // Then
        XCTAssertTrue(result, "保存空数据应该成功")
        
        // 清理测试文件
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    // MARK: - ID 范围过滤测试
    
    /// 测试：按 ID 范围保存（推荐帖子）
    func testSaveRecommendPosts() throws {
        // Given
        let posts = [
            Post(id: 1000, avatar: "", vip: false, name: "推荐1", date: "", isFollowed: false, text: "", images: [], commentCount: 0, likeCount: 0, isLiked: false),
            Post(id: 2000, avatar: "", vip: false, name: "热门1", date: "", isFollowed: false, text: "", images: [], commentCount: 0, likeCount: 0, isLiked: false),
            Post(id: 3000, avatar: "", vip: false, name: "视频1", date: "", isFollowed: false, text: "", images: [], commentCount: 0, likeCount: 0, isLiked: false)
        ]
        
        for post in posts {
            modelContext.insert(post)
        }
        try modelContext.save()
        
        // When
        let fileName = "PostListData_recommend_test.json"
        let result = JSONService.savePostsToJSON(fileName: fileName, modelContext: modelContext)
        
        // Then
        XCTAssertTrue(result)
        
        // 验证只保存了推荐和视频帖子（ID 1000-3999）
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent(fileName)
        
        if let data = try? Data(contentsOf: fileURL),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let list = json["list"] as? [[String: Any]] {
            XCTAssertEqual(list.count, 2, "应该只保存推荐和视频帖子")
        }
        
        // 清理测试文件
        try? FileManager.default.removeItem(at: fileURL)
    }
}

