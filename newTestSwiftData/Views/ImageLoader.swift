//
//  ImageLoader.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/23.
//

import SwiftUI
import UIKit

/// 图片加载工具
/// 负责从 Bundle 的 Resources 文件夹加载图片
struct ImageLoader {
    /// 从 Bundle 的 Resources 文件夹加载图片
    /// - Parameter fileName: 图片文件名
    /// - Returns: Image 视图，如果找不到则返回占位图
    static func loadImage(from fileName: String) -> Image {
        // 方法1: 尝试使用 URL 方式从 Resources 子目录加载（最可靠）
        if let url = Bundle.main.url(forResource: fileName, withExtension: nil, subdirectory: "Resources"),
           let imageData = try? Data(contentsOf: url),
           let uiImage = UIImage(data: imageData) {
            return Image(uiImage: uiImage)
        }
        
        // 方法2: 尝试使用路径方式从 Resources 子目录加载
        if let imagePath = Bundle.main.path(forResource: fileName, ofType: nil, inDirectory: "Resources"),
           let uiImage = UIImage(contentsOfFile: imagePath) {
            return Image(uiImage: uiImage)
        }
        
        // 方法3: 尝试去掉扩展名，然后指定类型
        let nameWithoutExt = (fileName as NSString).deletingPathExtension
        let fileExtension = (fileName as NSString).pathExtension
        if let imagePath = Bundle.main.path(forResource: nameWithoutExt, ofType: fileExtension, inDirectory: "Resources"),
           let uiImage = UIImage(contentsOfFile: imagePath) {
            return Image(uiImage: uiImage)
        }
        
        // 方法4: 尝试直接使用文件名（如果图片在 Bundle 根目录）
        if let uiImage = UIImage(named: fileName) {
            return Image(uiImage: uiImage)
        }
        
        // 如果都找不到，返回占位图
        // 创建一个灰色的占位 UIImage
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let placeholderImage = renderer.image { context in
            UIColor.gray.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            // 添加一个图标
            if let systemImage = UIImage(systemName: "photo") {
                systemImage.draw(in: CGRect(origin: .zero, size: size))
            }
        }
        return Image(uiImage: placeholderImage)
    }
    
    /// 加载 UIImage（用于图片网格）
    /// - Parameter name: 图片文件名
    /// - Returns: UIImage 或 nil
    static func loadUIImage(name: String) -> UIImage? {
        // 方法1: 尝试使用 URL 方式从 Resources 子目录加载
        if let url = Bundle.main.url(forResource: name, withExtension: nil, subdirectory: "Resources"),
           let imageData = try? Data(contentsOf: url),
           let uiImage = UIImage(data: imageData) {
            return uiImage
        }
        
        // 方法2: 尝试使用路径方式从 Resources 子目录加载
        if let imagePath = Bundle.main.path(forResource: name, ofType: nil, inDirectory: "Resources"),
           let uiImage = UIImage(contentsOfFile: imagePath) {
            return uiImage
        }
        
        // 方法3: 尝试去掉扩展名，然后指定类型
        let nameWithoutExt = (name as NSString).deletingPathExtension
        let fileExtension = (name as NSString).pathExtension
        if let imagePath = Bundle.main.path(forResource: nameWithoutExt, ofType: fileExtension, inDirectory: "Resources"),
           let uiImage = UIImage(contentsOfFile: imagePath) {
            return uiImage
        }
        
        // 方法4: 尝试直接使用文件名（如果图片在 Bundle 根目录）
        if let uiImage = UIImage(named: name) {
            return uiImage
        }
        
        return nil
    }
}
