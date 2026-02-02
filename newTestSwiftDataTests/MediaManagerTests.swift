//
//  MediaManagerTests.swift
//  newTestSwiftDataTests
//
//  Created by Unit Test Suite
//

import XCTest
import UIKit
@testable import newTestSwiftData

/// MediaManager 单元测试
final class MediaManagerTests: XCTestCase {
    
    var mediaManager: MediaManager!
    var testImageData: Data!
    
    // MARK: - 测试生命周期
    
    override func setUp() {
        super.setUp()
        mediaManager = MediaManager.shared
        
        // 创建测试图片数据
        let image = UIImage(systemName: "photo")!
        testImageData = image.pngData()!
    }
    
    override func tearDown() {
        // 清理测试数据
        mediaManager.clearAllMedia()
        mediaManager = nil
        testImageData = nil
        super.tearDown()
    }
    
    // MARK: - 保存图片测试
    
    /// 测试：保存图片
    func testSaveImage() {
        // When
        let relativePath = mediaManager.saveImage(data: testImageData)
        
        // Then
        XCTAssertNotNil(relativePath)
        XCTAssertTrue(relativePath!.hasPrefix("UserMedia/Images/"))
        XCTAssertTrue(relativePath!.hasSuffix(".jpg"))
    }
    
    /// 测试：保存多张图片
    func testSaveMultipleImages() {
        // When
        let path1 = mediaManager.saveImage(data: testImageData)
        let path2 = mediaManager.saveImage(data: testImageData)
        let path3 = mediaManager.saveImage(data: testImageData)
        
        // Then
        XCTAssertNotNil(path1)
        XCTAssertNotNil(path2)
        XCTAssertNotNil(path3)
        XCTAssertNotEqual(path1, path2, "不同图片应该有不同的路径")
        XCTAssertNotEqual(path2, path3, "不同图片应该有不同的路径")
    }
    
    // MARK: - 读取图片测试
    
    /// 测试：读取已保存的图片
    func testLoadImage() {
        // Given
        guard let relativePath = mediaManager.saveImage(data: testImageData) else {
            XCTFail("保存图片失败")
            return
        }
        
        // When
        let loadedImage = mediaManager.loadImage(relativePath: relativePath)
        
        // Then
        XCTAssertNotNil(loadedImage)
    }
    
    /// 测试：读取图片数据
    func testLoadImageData() {
        // Given
        guard let relativePath = mediaManager.saveImage(data: testImageData) else {
            XCTFail("保存图片失败")
            return
        }
        
        // When
        let loadedData = mediaManager.loadImageData(relativePath: relativePath)
        
        // Then
        XCTAssertNotNil(loadedData)
        XCTAssertGreaterThan(loadedData!.count, 0)
    }
    
    /// 测试：读取不存在的图片
    func testLoadNonExistentImage() {
        // When
        let image = mediaManager.loadImage(relativePath: "UserMedia/Images/nonexistent.jpg")
        
        // Then
        XCTAssertNil(image)
    }
    
    // MARK: - 删除图片测试
    
    /// 测试：删除已保存的图片
    func testDeleteMedia() {
        // Given
        guard let relativePath = mediaManager.saveImage(data: testImageData) else {
            XCTFail("保存图片失败")
            return
        }
        
        // When
        let result = mediaManager.deleteMedia(relativePath: relativePath)
        
        // Then
        XCTAssertTrue(result)
        
        // 验证文件已被删除
        let loadedImage = mediaManager.loadImage(relativePath: relativePath)
        XCTAssertNil(loadedImage)
    }
    
    /// 测试：删除不存在的图片
    func testDeleteNonExistentMedia() {
        // When
        let result = mediaManager.deleteMedia(relativePath: "UserMedia/Images/nonexistent.jpg")
        
        // Then
        XCTAssertFalse(result)
    }
    
    /// 测试：批量删除图片
    func testDeleteMultipleMedia() {
        // Given
        let path1 = mediaManager.saveImage(data: testImageData)!
        let path2 = mediaManager.saveImage(data: testImageData)!
        let path3 = mediaManager.saveImage(data: testImageData)!
        
        // When
        mediaManager.deleteMediaFiles(relativePaths: [path1, path2, path3])
        
        // Then
        XCTAssertNil(mediaManager.loadImage(relativePath: path1))
        XCTAssertNil(mediaManager.loadImage(relativePath: path2))
        XCTAssertNil(mediaManager.loadImage(relativePath: path3))
    }
    
    // MARK: - 工具方法测试
    
    /// 测试：获取媒体文件大小
    func testGetMediaSize() {
        // Given
        guard let relativePath = mediaManager.saveImage(data: testImageData) else {
            XCTFail("保存图片失败")
            return
        }
        
        // When
        let size = mediaManager.getMediaSize(relativePath: relativePath)
        
        // Then
        XCTAssertGreaterThan(size, 0)
    }
    
    /// 测试：获取格式化的文件大小
    func testGetFormattedMediaSize() {
        // Given
        guard let relativePath = mediaManager.saveImage(data: testImageData) else {
            XCTFail("保存图片失败")
            return
        }
        
        // When
        let formattedSize = mediaManager.getFormattedMediaSize(relativePath: relativePath)
        
        // Then
        XCTAssertFalse(formattedSize.isEmpty)
        XCTAssertTrue(formattedSize.contains("KB") || formattedSize.contains("MB") || formattedSize.contains("bytes"))
    }
    
    /// 测试：获取所有媒体文件
    func testGetAllMediaFiles() {
        // Given
        _ = mediaManager.saveImage(data: testImageData)
        _ = mediaManager.saveImage(data: testImageData)
        _ = mediaManager.saveImage(data: testImageData)
        
        // When
        let allFiles = mediaManager.getAllMediaFiles()
        
        // Then
        XCTAssertEqual(allFiles.count, 3)
    }
    
    /// 测试：获取媒体目录总大小
    func testGetTotalMediaSize() {
        // Given
        _ = mediaManager.saveImage(data: testImageData)
        _ = mediaManager.saveImage(data: testImageData)
        
        // When
        let totalSize = mediaManager.getTotalMediaSize()
        
        // Then
        XCTAssertGreaterThan(totalSize, 0)
    }
    
    /// 测试：清空所有媒体文件
    func testClearAllMedia() {
        // Given
        _ = mediaManager.saveImage(data: testImageData)
        _ = mediaManager.saveImage(data: testImageData)
        
        // When
        mediaManager.clearAllMedia()
        
        // Then
        let allFiles = mediaManager.getAllMediaFiles()
        XCTAssertEqual(allFiles.count, 0)
    }
    
    // MARK: - 获取媒体 URL 测试
    
    /// 测试：获取媒体文件 URL
    func testGetMediaURL() {
        // Given
        let relativePath = "UserMedia/Images/test.jpg"
        
        // When
        let url = mediaManager.getMediaURL(relativePath: relativePath)
        
        // Then
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.path.contains("UserMedia/Images/test.jpg"))
    }
}

