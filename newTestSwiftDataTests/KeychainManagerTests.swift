//
//  KeychainManagerTests.swift
//  newTestSwiftDataTests
//
//  Created by Unit Test Suite
//

import XCTest
@testable import newTestSwiftData

/// KeychainManager 单元测试
final class KeychainManagerTests: XCTestCase {
    
    var keychainManager: KeychainManager!
    
    // MARK: - 测试生命周期
    
    override func setUp() {
        super.setUp()
        keychainManager = KeychainManager.shared
        // 清空 Keychain
        keychainManager.clearAll()
    }
    
    override func tearDown() {
        // 清空 Keychain
        keychainManager.clearAll()
        keychainManager = nil
        super.tearDown()
    }
    
    // MARK: - Refresh Token 测试
    
    /// 测试：保存和读取 Refresh Token
    func testSaveAndGetRefreshToken() {
        // Given
        let token = "refresh_token_12345"
        
        // When
        let saveResult = keychainManager.saveRefreshToken(token)
        let retrievedToken = keychainManager.getRefreshToken()
        
        // Then
        XCTAssertTrue(saveResult)
        XCTAssertEqual(retrievedToken, token)
    }
    
    /// 测试：删除 Refresh Token
    func testDeleteRefreshToken() {
        // Given
        let token = "refresh_token_12345"
        keychainManager.saveRefreshToken(token)
        
        // When
        let deleteResult = keychainManager.deleteRefreshToken()
        let retrievedToken = keychainManager.getRefreshToken()
        
        // Then
        XCTAssertTrue(deleteResult)
        XCTAssertNil(retrievedToken)
    }
    
    /// 测试：更新 Refresh Token
    func testUpdateRefreshToken() {
        // Given
        let oldToken = "refresh_token_old"
        let newToken = "refresh_token_new"
        keychainManager.saveRefreshToken(oldToken)
        
        // When
        keychainManager.saveRefreshToken(newToken)
        let retrievedToken = keychainManager.getRefreshToken()
        
        // Then
        XCTAssertEqual(retrievedToken, newToken)
    }
    
    // MARK: - Access Token 测试
    
    /// 测试：保存和读取 Access Token
    func testSaveAndGetAccessToken() {
        // Given
        let token = "access_token_12345"
        
        // When
        let saveResult = keychainManager.saveAccessToken(token)
        let retrievedToken = keychainManager.getAccessToken()
        
        // Then
        XCTAssertTrue(saveResult)
        XCTAssertEqual(retrievedToken, token)
    }
    
    /// 测试：删除 Access Token
    func testDeleteAccessToken() {
        // Given
        let token = "access_token_12345"
        keychainManager.saveAccessToken(token)
        
        // When
        let deleteResult = keychainManager.deleteAccessToken()
        let retrievedToken = keychainManager.getAccessToken()
        
        // Then
        XCTAssertTrue(deleteResult)
        XCTAssertNil(retrievedToken)
    }
    
    // MARK: - 清空所有 Token 测试
    
    /// 测试：清空所有 Token
    func testClearAll() {
        // Given
        keychainManager.saveRefreshToken("refresh_token")
        keychainManager.saveAccessToken("access_token")
        
        // When
        let clearResult = keychainManager.clearAll()
        let refreshToken = keychainManager.getRefreshToken()
        let accessToken = keychainManager.getAccessToken()
        
        // Then
        XCTAssertTrue(clearResult)
        XCTAssertNil(refreshToken)
        XCTAssertNil(accessToken)
    }
    
    // MARK: - 边界情况测试
    
    /// 测试：保存空字符串
    func testSaveEmptyString() {
        // Given
        let emptyToken = ""
        
        // When
        let saveResult = keychainManager.saveRefreshToken(emptyToken)
        let retrievedToken = keychainManager.getRefreshToken()
        
        // Then
        XCTAssertTrue(saveResult)
        XCTAssertEqual(retrievedToken, emptyToken)
    }
    
    /// 测试：保存长字符串
    func testSaveLongString() {
        // Given
        let longToken = String(repeating: "a", count: 10000)
        
        // When
        let saveResult = keychainManager.saveRefreshToken(longToken)
        let retrievedToken = keychainManager.getRefreshToken()
        
        // Then
        XCTAssertTrue(saveResult)
        XCTAssertEqual(retrievedToken, longToken)
    }
    
    /// 测试：读取不存在的 Token
    func testGetNonExistentToken() {
        // When
        let token = keychainManager.getRefreshToken()
        
        // Then
        XCTAssertNil(token)
    }
    
    /// 测试：多次保存同一个 Token
    func testMultipleSaves() {
        // Given
        let token = "test_token"
        
        // When
        keychainManager.saveRefreshToken(token)
        keychainManager.saveRefreshToken(token)
        keychainManager.saveRefreshToken(token)
        let retrievedToken = keychainManager.getRefreshToken()
        
        // Then
        XCTAssertEqual(retrievedToken, token)
    }
}

