//
//  ImageLoader.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/23.
//

import SwiftUI
import SDWebImageSwiftUI

/// 网络图片加载视图
/// 支持从网络加载图片，带有加载动画和占位效果
/// 使用 NetworkManager 中的 baseURL 统一管理 URL
struct NetworkImageView: View {
    let imageURL: String
    
    var body: some View {
        WebImage(url: URL(string: NetworkAPIBaseURL + imageURL)) { image in
            image
                .resizable()
        } placeholder: {
            // 加载中的占位视图 - 类似微博/小红书的效果
            ShimmerPlaceholder()
        }
        .onSuccess { image, data, cacheType in
            // 图片加载成功
        }
        .onFailure { error in
            // 图片加载失败
            print("图片加载失败: \(error.localizedDescription)")
        }
        .indicator(Indicator.activity) // 显示加载指示器
        .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.3))) // 淡入动画
    }
}

/// 闪烁占位效果（类似微博、小红书）
struct ShimmerPlaceholder: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // 背景色
            Color(UIColor.systemGray6)
            
            // 闪烁渐变效果
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(UIColor.systemGray6),
                    Color(UIColor.systemGray5),
                    Color(UIColor.systemGray6)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .opacity(0.6)
            .offset(x: isAnimating ? 400 : -400)
            .animation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false),
                value: isAnimating
            )
            
            // 图片图标
            Image(systemName: "photo")
                .font(.system(size: 30))
                .foregroundColor(Color(UIColor.systemGray4))
        }
        .onAppear {
            isAnimating = true
        }
    }
}

/// 图片加载工具
/// 兼容旧版本，支持本地和网络图片加载
struct ImageLoader {
    /// 从网络或本地加载图片
    /// - Parameter fileName: 图片文件名或 URL
    /// - Returns: Image 视图
    static func loadImage(from fileName: String) -> Image {
        // 如果是网络 URL，使用 NetworkImageView
        if fileName.hasPrefix("http://") || fileName.hasPrefix("https://") {
            // 注意：这里返回的是 Image，但实际应该使用 NetworkImageView
            // 为了保持接口兼容，这里先返回占位图
            return Image(systemName: "photo")
        }
        
        // 本地图片加载逻辑（保持原有逻辑）
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
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let placeholderImage = renderer.image { context in
            UIColor.systemGray6.setFill()
            context.fill(CGRect(origin: .zero, size: size))
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
