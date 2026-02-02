//
//  SmartImageView.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/2/1.
//

import SwiftUI
import SDWebImageSwiftUI

/// 智能图片加载视图
/// 自动判断是网络图片还是本地图片，并使用相应的加载方式
struct SmartImageView: View {
    let imagePath: String
    
    var body: some View {
        Group {
            if isLocalImage(imagePath) {
                // 本地图片（用户发布的帖子）
                LocalImageView(relativePath: imagePath)
            } else {
                // 网络图片（从服务器加载）
                NetworkImageView(imageURL: imagePath)
            }
        }
    }
    
    /// 判断是否为本地图片
    private func isLocalImage(_ path: String) -> Bool {
        // 本地图片路径特征：
        // 1. 以 "UserMedia/" 开头
        // 2. 以 "local://" 开头
        return path.hasPrefix("UserMedia/") || path.hasPrefix("local://")
    }
}

/// 本地图片加载视图
struct LocalImageView: View {
    let relativePath: String
    @State private var uiImage: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let image = uiImage {
                Image(uiImage: image)
                    .resizable()
            } else if isLoading {
                // 加载中
                ShimmerPlaceholder()
            } else {
                // 加载失败
                placeholderView
            }
        }
        .onAppear {
            loadLocalImage()
        }
    }
    
    /// 加载本地图片
    private func loadLocalImage() {
        // 处理 local:// 前缀
        let cleanPath = relativePath.replacingOccurrences(of: "local://", with: "")
        
        // 从 MediaManager 获取图片
        if let imageURL = MediaManager.shared.getMediaURL(relativePath: cleanPath),
           let loadedImage = UIImage(contentsOfFile: imageURL.path) {
            DispatchQueue.main.async {
                self.uiImage = loadedImage
                self.isLoading = false
            }
        } else {
            // 加载失败
            print("⚠️ 本地图片加载失败: \(cleanPath)")
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
    
    /// 占位视图
    private var placeholderView: some View {
        ZStack {
            Color(UIColor.systemGray6)
            
            VStack(spacing: 8) {
                Image(systemName: "photo.fill")
                    .font(.system(size: 30))
                    .foregroundColor(Color(UIColor.systemGray4))
                
                Text("图片加载失败")
                    .font(.caption)
                    .foregroundColor(Color(UIColor.systemGray3))
            }
        }
    }
}

/// 预览
#Preview {
    VStack(spacing: 20) {
        // 网络图片
        SmartImageView(imagePath: "avatar1.jpg")
            .frame(width: 100, height: 100)
            .clipShape(Circle())
        
        // 本地图片
        SmartImageView(imagePath: "UserMedia/Images/IMG_123456_abcd.jpg")
            .frame(width: 200, height: 200)
            .cornerRadius(12)
    }
    .padding()
}

