//
//  MediaManager.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/2/1.
//

import Foundation
import UIKit
import AVFoundation

/// 媒体类型枚举
enum MediaType {
    case image
    case video
}

/// 媒体管理器 - 负责本地媒体文件的存储和管理
class MediaManager {
    static let shared = MediaManager()
    
    private init() {}
    
    // MARK: - 目录管理
    
    /// 获取媒体存储根目录
    private var mediaDirectory: URL {
        let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        
        let mediaURL = documentsURL.appendingPathComponent("UserMedia")
        
        // 创建目录（如果不存在）
        if !FileManager.default.fileExists(atPath: mediaURL.path) {
            try? FileManager.default.createDirectory(
                at: mediaURL,
                withIntermediateDirectories: true
            )
        }
        
        return mediaURL
    }
    
    /// 获取图片存储目录
    private var imagesDirectory: URL {
        let imagesURL = mediaDirectory.appendingPathComponent("Images")
        if !FileManager.default.fileExists(atPath: imagesURL.path) {
            try? FileManager.default.createDirectory(
                at: imagesURL,
                withIntermediateDirectories: true
            )
        }
        return imagesURL
    }
    
    /// 获取视频存储目录
    private var videosDirectory: URL {
        let videosURL = mediaDirectory.appendingPathComponent("Videos")
        if !FileManager.default.fileExists(atPath: videosURL.path) {
            try? FileManager.default.createDirectory(
                at: videosURL,
                withIntermediateDirectories: true
            )
        }
        return videosURL
    }
    
    // MARK: - 保存媒体文件
    
    /// 保存图片到本地
    /// - Parameter data: 图片数据
    /// - Returns: 本地文件路径（相对路径，格式：UserMedia/Images/xxx.jpg）
    func saveImage(data: Data) -> String? {
        let timestamp = Int(Date().timeIntervalSince1970)
        let uuid = UUID().uuidString.prefix(8)
        let fileName = "IMG_\(timestamp)_\(uuid).jpg"
        
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        
        do {
            // 压缩图片（可选）
            if let image = UIImage(data: data),
               let compressedData = image.jpegData(compressionQuality: 0.8) {
                try compressedData.write(to: fileURL)
            } else {
                try data.write(to: fileURL)
            }
            
            // 返回相对路径
            let relativePath = "UserMedia/Images/\(fileName)"
            print("✅ 图片已保存: \(relativePath)")
            return relativePath
            
        } catch {
            print("❌ 保存图片失败: \(error)")
            return nil
        }
    }
    
    /// 保存视频到本地
    /// - Parameter data: 视频数据
    /// - Returns: 本地文件路径（相对路径，格式：UserMedia/Videos/xxx.mp4）
    func saveVideo(data: Data) -> String? {
        let timestamp = Int(Date().timeIntervalSince1970)
        let uuid = UUID().uuidString.prefix(8)
        let fileName = "VID_\(timestamp)_\(uuid).mp4"
        
        let fileURL = videosDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            
            // 返回相对路径
            let relativePath = "UserMedia/Videos/\(fileName)"
            print("✅ 视频已保存: \(relativePath)")
            return relativePath
            
        } catch {
            print("❌ 保存视频失败: \(error)")
            return nil
        }
    }
    
    /// 通用保存方法
    /// - Parameters:
    ///   - data: 媒体数据
    ///   - type: 媒体类型
    /// - Returns: 本地文件路径（相对路径）
    func saveMedia(data: Data, type: MediaType) -> String? {
        switch type {
        case .image:
            return saveImage(data: data)
        case .video:
            return saveVideo(data: data)
        }
    }
    
    // MARK: - 读取媒体文件
    
    /// 获取媒体文件的完整 URL
    /// - Parameter relativePath: 相对路径（如：UserMedia/Images/xxx.jpg）
    /// - Returns: 完整的文件 URL
    func getMediaURL(relativePath: String) -> URL? {
        let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        
        return documentsURL.appendingPathComponent(relativePath)
    }
    
    /// 读取图片数据
    /// - Parameter relativePath: 相对路径
    /// - Returns: 图片数据
    func loadImageData(relativePath: String) -> Data? {
        guard let url = getMediaURL(relativePath: relativePath) else {
            return nil
        }
        return try? Data(contentsOf: url)
    }
    
    /// 读取 UIImage
    /// - Parameter relativePath: 相对路径
    /// - Returns: UIImage 对象
    func loadImage(relativePath: String) -> UIImage? {
        guard let data = loadImageData(relativePath: relativePath) else {
            return nil
        }
        return UIImage(data: data)
    }
    
    // MARK: - 删除媒体文件
    
    /// 删除媒体文件
    /// - Parameter relativePath: 相对路径
    /// - Returns: 是否删除成功
    @discardableResult
    func deleteMedia(relativePath: String) -> Bool {
        guard let url = getMediaURL(relativePath: relativePath) else {
            return false
        }
        
        do {
            try FileManager.default.removeItem(at: url)
            print("✅ 已删除媒体文件: \(relativePath)")
            return true
        } catch {
            print("❌ 删除媒体文件失败: \(error)")
            return false
        }
    }
    
    /// 删除多个媒体文件
    /// - Parameter relativePaths: 相对路径数组
    func deleteMediaFiles(relativePaths: [String]) {
        for path in relativePaths {
            deleteMedia(relativePath: path)
        }
    }
    
    // MARK: - 工具方法
    
    /// 获取媒体文件大小
    /// - Parameter relativePath: 相对路径
    /// - Returns: 文件大小（字节）
    func getMediaSize(relativePath: String) -> Int64 {
        guard let url = getMediaURL(relativePath: relativePath) else {
            return 0
        }
        
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        return attributes?[.size] as? Int64 ?? 0
    }
    
    /// 获取格式化的文件大小
    /// - Parameter relativePath: 相对路径
    /// - Returns: 格式化的大小字符串（如：1.5 MB）
    func getFormattedMediaSize(relativePath: String) -> String {
        let bytes = getMediaSize(relativePath: relativePath)
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    /// 生成视频缩略图
    /// - Parameter relativePath: 视频相对路径
    /// - Returns: 缩略图 UIImage
    func generateVideoThumbnail(relativePath: String) -> UIImage? {
        guard let url = getMediaURL(relativePath: relativePath) else {
            return nil
        }
        
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: 1, preferredTimescale: 60)
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            print("❌ 生成视频缩略图失败: \(error)")
            return nil
        }
    }
    
    /// 获取所有用户媒体文件
    /// - Returns: 媒体文件相对路径数组
    func getAllMediaFiles() -> [String] {
        var allFiles: [String] = []
        
        // 获取所有图片
        if let imageFiles = try? FileManager.default.contentsOfDirectory(atPath: imagesDirectory.path) {
            allFiles += imageFiles.map { "UserMedia/Images/\($0)" }
        }
        
        // 获取所有视频
        if let videoFiles = try? FileManager.default.contentsOfDirectory(atPath: videosDirectory.path) {
            allFiles += videoFiles.map { "UserMedia/Videos/\($0)" }
        }
        
        return allFiles
    }
    
    /// 清理所有媒体文件
    func clearAllMedia() {
        do {
            try FileManager.default.removeItem(at: mediaDirectory)
            print("✅ 已清理所有媒体文件")
        } catch {
            print("❌ 清理媒体文件失败: \(error)")
        }
    }
    
    /// 获取媒体目录总大小
    /// - Returns: 总大小（字节）
    func getTotalMediaSize() -> Int64 {
        let allFiles = getAllMediaFiles()
        return allFiles.reduce(0) { $0 + getMediaSize(relativePath: $1) }
    }
    
    /// 获取格式化的总大小
    /// - Returns: 格式化的大小字符串
    func getFormattedTotalSize() -> String {
        let bytes = getTotalMediaSize()
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

