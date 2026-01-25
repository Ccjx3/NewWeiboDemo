//
//  NativePhotoBrowser.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/24.
//

import SwiftUI
import UIKit
import SDWebImageSwiftUI

/// 原生图片浏览器 - 仿小红书/微博效果
/// 功能：
/// 1. 全屏显示图片
/// 2. 左右滑动切换
/// 3. 双击放大/缩放
/// 4. 捏合手势缩放
/// 5. 下滑关闭
/// 6. 页码指示器
struct NativePhotoBrowser: View {
    @Binding var isPresented: Bool
    let images: [String]
    let initialIndex: Int
    
    @State private var currentIndex: Int
    @State private var offset: CGSize = .zero
    @State private var isDragging = false
    
    init(isPresented: Binding<Bool>, images: [String], initialIndex: Int) {
        self._isPresented = isPresented
        self.images = images
        self.initialIndex = initialIndex
        // 关键修复：直接使用 initialIndex 初始化 currentIndex
        self._currentIndex = State(initialValue: initialIndex)
        print("🔧 NativePhotoBrowser 初始化，initialIndex: \(initialIndex + 1)/\(images.count)")
    }
    
    var body: some View {
        ZStack {
            // 黑色背景
            Color.black
                .ignoresSafeArea()
                .opacity(isDragging ? max(0.3, 1 - abs(offset.height) / CGFloat(500)) : 1)
            
            // 图片浏览器 - 关键修复：使用唯一的 UUID 作为 key
            TabView(selection: $currentIndex) {
                ForEach(0..<images.count, id: \.self) { index in
                    ZoomableImageView(
                        imageName: images[index],
                        onDismiss: {
                            withAnimation(.spring()) {
                                isPresented = false
                            }
                        }
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .offset(y: offset.height)
            
            // 顶部工具栏
            VStack {
                HStack {
                    // 关闭按钮
                    Button(action: {
                        withAnimation {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // 页码指示器
                    Text("\(currentIndex + 1) / \(images.count)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(20)
                }
                .padding()
                
                Spacer()
            }
            .opacity(isDragging ? 0 : 1)
        }
    }
}

/// 可缩放的图片视图
struct ZoomableImageView: View {
    let imageName: String
    let onDismiss: () -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var dismissOffset: CGFloat = 0
    @GestureState private var dragState: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            // 使用网络图片加载
            WebImage(url: URL(string: imageName)) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                ShimmerPlaceholder()
            }
            .onSuccess { image, data, cacheType in
                print("✅ 图片加载成功: \(imageName)")
            }
            .onFailure { error in
                print("❌ 图片加载失败: \(error.localizedDescription)")
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .scaleEffect(scale)
            .offset(x: offset.width, y: offset.height + dismissOffset)
            // 双击手势 - 放大/缩小
            .onTapGesture(count: 2) {
                withAnimation(.spring(response: 0.3)) {
                    if scale > 1 {
                        scale = 1
                        offset = .zero
                        lastOffset = .zero
                    } else {
                        scale = 2.5
                    }
                }
            }
            // 捏合缩放手势
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        let delta = value / lastScale
                        lastScale = value
                        let newScale = scale * delta
                        scale = min(max(newScale, 1), 4)
                    }
                    .onEnded { _ in
                        lastScale = 1.0
                        withAnimation(.spring()) {
                            if scale < 1 {
                                scale = 1
                                offset = .zero
                                lastOffset = .zero
                            }
                        }
                    }
            )
            // 拖动手势 - 修复：只在特定条件下拦截手势
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        if scale > 1.1 {
                            // 放大状态：允许拖动查看细节（高优先级）
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        } else {
                            // 未放大状态：只处理垂直拖动
                            let horizontalAmount = abs(value.translation.width)
                            let verticalAmount = abs(value.translation.height)
                            
                            // 只有当垂直拖动明显大于水平拖动时才拦截
                            if verticalAmount > horizontalAmount * 1.5 && verticalAmount > 30 {
                                dismissOffset = value.translation.height
                            }
                        }
                    }
                    .onEnded { value in
                        if scale > 1.1 {
                            // 放大状态：记录偏移
                            lastOffset = offset
                        } else {
                            // 未放大状态：判断是否关闭
                            let verticalAmount = abs(value.translation.height)
                            let horizontalAmount = abs(value.translation.width)
                            
                            if verticalAmount > horizontalAmount * 1.5 && verticalAmount > 150 {
                                onDismiss()
                            } else {
                                withAnimation(.spring()) {
                                    dismissOffset = 0
                                }
                            }
                        }
                    },
                including: scale > 1.1 ? .all : .subviews
            )
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var showBrowser = false
        
        var body: some View {
            VStack {
                Button("显示图片浏览器") {
                    showBrowser = true
                }
            }
            .fullScreenCover(isPresented: $showBrowser) {
                NativePhotoBrowser(
                    isPresented: $showBrowser,
                    images: ["avatar1.png", "avatar2.png"],
                    initialIndex: 0
                )
            }
        }
    }
    
    return PreviewWrapper()
}
