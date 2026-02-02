//
//  UserTests.swift
//  newTestSwiftDataTests
//
//  Created by Unit Test Suite
//

import XCTest
import SwiftData
@testable import newTestSwiftData

/// User 模型单元测试
final class UserTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    // MARK: - 测试生命周期
    
    override func setUp() {
        super.setUp()
        
        // 创建内存数据库用于测试
        let schema = Schema([User.self, Token.self])
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
    
    // MARK: - 用户创建测试
    
    /// 测试：创建用户
    func testCreateUser() {
        // Given
        let user = User(
            id: 1,
            username: "testuser",
            password: "password123",
            email: "test@example.com"
        )
        
        // When
        modelContext.insert(user)
        
        // Then
        XCTAssertEqual(user.username, "testuser")
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertFalse(user.isPreset)
        XCTAssertNotNil(user.createdAt)
        XCTAssertNil(user.lastLoginAt)
    }
    
    /// 测试：创建预置用户
    func testCreatePresetUser() {
        // Given & When
        let user = User(
            id: 1,
            username: "admin",
            password: "123456",
            email: "admin@example.com",
            isPreset: true
        )
        
        // Then
        XCTAssertTrue(user.isPreset)
    }
    
    // MARK: - 密码验证测试
    
    /// 测试：密码验证成功
    func testValidatePasswordSuccess() {
        // Given
        let user = User(
            id: 1,
            username: "testuser",
            password: "password123",
            email: "test@example.com"
        )
        
        // When
        let isValid = user.validatePassword("password123")
        
        // Then
        XCTAssertTrue(isValid)
    }
    
    /// 测试：密码验证失败
    func testValidatePasswordFailure() {
        // Given
        let user = User(
            id: 1,
            username: "testuser",
            password: "password123",
            email: "test@example.com"
        )
        
        // When
        let isValid = user.validatePassword("wrongpassword")
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    // MARK: - 登录时间更新测试
    
    /// 测试：更新最后登录时间
    func testUpdateLastLogin() {
        // Given
        let user = User(
            id: 1,
            username: "testuser",
            password: "password123",
            email: "test@example.com"
        )
        XCTAssertNil(user.lastLoginAt)
        
        // When
        user.updateLastLogin()
        
        // Then
        XCTAssertNotNil(user.lastLoginAt)
        XCTAssertTrue(user.lastLoginAt! <= Date())
    }
    
    // MARK: - 数据转换测试
    
    /// 测试：转换为 UserInfo
    func testToUserInfo() {
        // Given
        let user = User(
            id: 1,
            username: "testuser",
            password: "password123",
            email: "test@example.com"
        )
        
        // When
        let userInfo = user.toUserInfo()
        
        // Then
        XCTAssertEqual(userInfo.id, 1)
        XCTAssertEqual(userInfo.username, "testuser")
        XCTAssertEqual(userInfo.email, "test@example.com")
    }
    
    // MARK: - SwiftData 持久化测试
    
    /// 测试：保存用户到 SwiftData
    func testSaveUserToSwiftData() throws {
        // Given
        let user = User(
            id: 1,
            username: "testuser",
            password: "password123",
            email: "test@example.com"
        )
        
        // When
        modelContext.insert(user)
        try modelContext.save()
        
        // Then
        let descriptor = FetchDescriptor<User>()
        let users = try modelContext.fetch(descriptor)
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users.first?.username, "testuser")
    }
    
    /// 测试：查询用户
    func testFetchUser() throws {
        // Given
        let user = User(
            id: 1,
            username: "testuser",
            password: "password123",
            email: "test@example.com"
        )
        modelContext.insert(user)
        try modelContext.save()
        
        // When
        let username = "testuser"
        let predicate = #Predicate<User> { u in
            u.username == username
        }
        let descriptor = FetchDescriptor<User>(predicate: predicate)
        let fetchedUsers = try modelContext.fetch(descriptor)
        
        // Then
        XCTAssertEqual(fetchedUsers.count, 1)
        XCTAssertEqual(fetchedUsers.first?.id, 1)
    }
    
    /// 测试：唯一性约束
    func testUniqueConstraint() throws {
        // Given
        let user1 = User(
            id: 1,
            username: "testuser",
            password: "password123",
            email: "test@example.com"
        )
        let user2 = User(
            id: 1,
            username: "testuser2",
            password: "password456",
            email: "test2@example.com"
        )
        
        // When
        modelContext.insert(user1)
        try modelContext.save()
        
        modelContext.insert(user2)
        
        // Then
        // SwiftData 应该抛出错误或覆盖旧数据
        XCTAssertThrowsError(try modelContext.save())
    }
}

