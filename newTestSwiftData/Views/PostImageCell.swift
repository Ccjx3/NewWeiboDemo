//
//  PostImageCell.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/23.
//

import SwiftUI

/// 控制图片间距
private let kImageSpace: CGFloat = 6

/// 帖子图片单元格组件
/// 根据图片数量自动调整布局
struct PostImageCell: View {
    let images: [String]
    let width: CGFloat
    
    var body: some View {
        Group {
            if images.count == 1 {
                if let uiImage = ImageLoader.loadUIImage(name: images[0]) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: width, height: width * 0.75)
                        .clipped()
                        .cornerRadius(8)
                } else {
                    placeholderView(width: width, height: width * 0.75)
                }
            } else if images.count == 2 {
                PostImageCellRow(images: images, width: width)
            } else if images.count == 3 {
                PostImageCellRow(images: images, width: width)
            } else if images.count == 4 {
                VStack(spacing: kImageSpace) {
                    PostImageCellRow(images: Array(images[0...1]), width: width)
                    PostImageCellRow(images: Array(images[2...3]), width: width)
                }
            } else if images.count == 5 {
                VStack(spacing: kImageSpace) {
                    PostImageCellRow(images: Array(images[0...1]), width: width)
                    PostImageCellRow(images: Array(images[2...4]), width: width)
                }
            } else if images.count == 6 {
                VStack(spacing: kImageSpace) {
                    PostImageCellRow(images: Array(images[0...2]), width: width)
                    PostImageCellRow(images: Array(images[3...5]), width: width)
                }
            } else {
                // 超过 6 张，只显示前 6 张
                VStack(spacing: kImageSpace) {
                    PostImageCellRow(images: Array(images[0...2]), width: width)
                    PostImageCellRow(images: Array(images[3...5]), width: width)
                }
            }
        }
    }
    
    /// 占位图视图
    private func placeholderView(width: CGFloat, height: CGFloat) -> some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: width, height: height)
            .overlay(
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
            )
            .cornerRadius(8)
    }
}

/// 图片行组件
/// 用于显示一行图片
struct PostImageCellRow: View {
    let images: [String]
    let width: CGFloat
    
    var body: some View {
        HStack(spacing: kImageSpace) {
            ForEach(images, id: \.self) { image in
                let imageSize = (width - kImageSpace * CGFloat(images.count - 1)) / CGFloat(images.count)
                
                if let uiImage = ImageLoader.loadUIImage(name: image) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: imageSize, height: imageSize)
                        .clipped()
                        .cornerRadius(8)
                } else {
                    // 占位图
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: imageSize, height: imageSize)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                        .cornerRadius(8)
                }
            }
        }
    }
}
