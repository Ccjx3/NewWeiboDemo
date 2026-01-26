//
//  PostImageCell.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/23.
//

import SwiftUI
import SDWebImageSwiftUI

/// 控制图片间距
private let kImageSpace: CGFloat = 6

/// 帖子图片单元格组件
/// 根据图片数量自动调整布局
/// 支持点击图片进入全屏预览模式
struct PostImageCell: View {
    let images: [String]
    let width: CGFloat
    
    /// 控制图片浏览器的显示状态
    @State private var showPhotoBrowser = false
    
    /// 记录用户点击的图片索引
    /// 用于在浏览器中定位到对应的图片
    @State private var selectedImageIndex = 0
    
    var body: some View {
        Group {
            if images.count == 1 {
                // 单张图片布局 - 使用网络图片
                WebImage(url: URL(string: NetworkAPIBaseURL + images[0])) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    ShimmerPlaceholder()
                }
                .onSuccess { image, data, cacheType in
                    // 图片加载成功
                }
                .frame(width: width, height: width * 0.75)
                .clipped()
                .cornerRadius(8)
                .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.3)))
                // 添加点击手势，点击后显示图片浏览器
                .onTapGesture {
                    print("📷 点击了第 1 张图片（单图），准备打开浏览器")
                    selectedImageIndex = 0  // 单张图片索引为 0
                    // 使用延迟确保 selectedImageIndex 已经更新
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        showPhotoBrowser = true
                    }
                }
            } else if images.count == 2 {
                // 两张图片横向排列
                PostImageCellRow(
                    images: images,
                    width: width,
                    onImageTap: handleImageTap  // 传递点击回调
                )
            } else if images.count == 3 {
                // 三张图片横向排列
                PostImageCellRow(
                    images: images,
                    width: width,
                    onImageTap: handleImageTap
                )
            } else if images.count == 4 {
                // 四张图片 2x2 网格布局
                VStack(spacing: kImageSpace) {
                    PostImageCellRow(
                        images: Array(images[0...1]),
                        width: width,
                        startIndex: 0,  // 第一行起始索引为 0
                        onImageTap: handleImageTap
                    )
                    PostImageCellRow(
                        images: Array(images[2...3]),
                        width: width,
                        startIndex: 2,  // 第二行起始索引为 2
                        onImageTap: handleImageTap
                    )
                }
            } else if images.count == 5 {
                // 五张图片：第一行 2 张，第二行 3 张
                VStack(spacing: kImageSpace) {
                    PostImageCellRow(
                        images: Array(images[0...1]),
                        width: width,
                        startIndex: 0,
                        onImageTap: handleImageTap
                    )
                    PostImageCellRow(
                        images: Array(images[2...4]),
                        width: width,
                        startIndex: 2,
                        onImageTap: handleImageTap
                    )
                }
            } else if images.count == 6 {
                // 六张图片 2x3 网格布局
                VStack(spacing: kImageSpace) {
                    PostImageCellRow(
                        images: Array(images[0...2]),
                        width: width,
                        startIndex: 0,
                        onImageTap: handleImageTap
                    )
                    PostImageCellRow(
                        images: Array(images[3...5]),
                        width: width,
                        startIndex: 3,
                        onImageTap: handleImageTap
                    )
                }
            } else {
                // 超过 6 张，只显示前 6 张
                VStack(spacing: kImageSpace) {
                    PostImageCellRow(
                        images: Array(images[0...2]),
                        width: width,
                        startIndex: 0,
                        onImageTap: handleImageTap
                    )
                    PostImageCellRow(
                        images: Array(images[3...5]),
                        width: width,
                        startIndex: 3,
                        onImageTap: handleImageTap
                    )
                }
            }
        }
        // 使用 fullScreenCover 全屏显示图片浏览器
        // fullScreenCover 会覆盖整个屏幕，提供沉浸式体验
        .fullScreenCover(isPresented: $showPhotoBrowser) {
            // 使用原生图片浏览器（仿小红书/微博效果）
            NativePhotoBrowser(
                isPresented: $showPhotoBrowser,
                images: images.map { NetworkAPIBaseURL + $0 }, // 转换为完整 URL
                initialIndex: selectedImageIndex
            )
            .id(selectedImageIndex) // 关键修复：使用 selectedImageIndex 作为 id，确保每次点击不同图片都重新创建视图
        }
    }
    
    /// 处理图片点击事件
    /// - Parameter index: 被点击图片的索引
    private func handleImageTap(index: Int) {
        print("📷 点击了第 \(index + 1) 张图片，准备打开浏览器")
        selectedImageIndex = index
        // 使用延迟确保 selectedImageIndex 已经更新
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            showPhotoBrowser = true
        }
    }
}

/// 图片行组件
/// 用于显示一行图片，支持点击预览
struct PostImageCellRow: View {
    let images: [String]
    let width: CGFloat
    
    /// 起始索引，用于计算每张图片在整个图片数组中的实际位置
    /// 例如：第二行的起始索引可能是 2 或 3
    var startIndex: Int = 0
    
    /// 图片点击回调
    /// 参数是图片在整个数组中的索引
    var onImageTap: ((Int) -> Void)? = nil
    
    var body: some View {
        HStack(spacing: kImageSpace) {
            // 使用 enumerated() 获取每个图片在当前行中的索引
            ForEach(Array(images.enumerated()), id: \.element) { rowIndex, image in
                // 计算图片尺寸
                // 总宽度减去间距，然后平均分配给每张图片
                let imageSize = (width - kImageSpace * CGFloat(images.count - 1)) / CGFloat(images.count)
                
                // 计算图片在整个数组中的实际索引
                let actualIndex = startIndex + rowIndex
                
                // 使用网络图片加载
                WebImage(url: URL(string: NetworkAPIBaseURL + image)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    ShimmerPlaceholder()
                }
                .onSuccess { image, data, cacheType in
                    // 图片加载成功
                }
                .frame(width: imageSize, height: imageSize)
                .clipped()
                .cornerRadius(8)
                .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.3)))
                // 添加点击手势
                .onTapGesture {
                    // 触发回调，传递实际索引
                    onImageTap?(actualIndex)
                }
            }
        }
    }
}
