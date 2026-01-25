//
//  PhotoBrowserWrapper.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/24.
//

import SwiftUI
import UIKit

/// JXPhotoBrowser 的 SwiftUI 包装器
/// 这个组件负责将 UIKit 的 JXPhotoBrowser 桥接到 SwiftUI 中使用
/// 
/// 设计思路：
/// 1. 使用 UIViewControllerRepresentable 协议将 UIKit 的 ViewController 桥接到 SwiftUI
/// 2. 通过 Binding 控制显示/隐藏状态
/// 3. 支持传入图片数组和初始索引
struct PhotoBrowserWrapper: UIViewControllerRepresentable {
    
    // MARK: - Properties
    
    /// 控制图片浏览器的显示/隐藏状态
    /// 使用 @Binding 可以让父视图控制这个状态
    @Binding var isPresented: Bool
    
    /// 要显示的图片文件名数组
    /// 这些图片文件存储在 Bundle 的 Resources 文件夹中
    let imageNames: [String]
    
    /// 初始显示的图片索引（从 0 开始）
    /// 用户点击第几张图片，就从第几张开始显示
    let initialIndex: Int
    
    // MARK: - UIViewControllerRepresentable Protocol Methods
    
    /// 创建并返回一个 UIViewController
    /// 这个方法只会在首次创建时调用一次
    /// - Parameter context: 上下文对象，包含协调器等信息
    /// - Returns: 返回一个空的 UIViewController 作为容器
    func makeUIViewController(context: Context) -> UIViewController {
        // 返回一个空的 ViewController 作为容器
        // 实际的 JXPhotoBrowser 会在 updateUIViewController 中以 present 方式显示
        return UIViewController()
    }
    
    /// 更新 UIViewController 的状态
    /// 当 SwiftUI 的状态发生变化时（如 isPresented 改变），这个方法会被调用
    /// - Parameters:
    ///   - uiViewController: 之前创建的 UIViewController
    ///   - context: 上下文对象
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // 当 isPresented 为 true 且还没有显示浏览器时，显示图片浏览器
        if isPresented && uiViewController.presentedViewController == nil {
            showPhotoBrowser(from: uiViewController)
        }
        // 当 isPresented 为 false 且浏览器正在显示时，关闭浏览器
        else if !isPresented && uiViewController.presentedViewController != nil {
            uiViewController.dismiss(animated: true)
        }
    }
    
    // MARK: - Private Methods
    
    /// 显示图片浏览器
    /// 这个方法负责配置和显示 JXPhotoBrowser
    /// - Parameter viewController: 用于 present 浏览器的 ViewController
    private func showPhotoBrowser(from viewController: UIViewController) {
        // 动态导入 JXPhotoBrowser 模块
        // 由于 JXPhotoBrowser 是 Objective-C 框架，需要通过运行时动态获取类
        guard let browserClass = NSClassFromString("JXPhotoBrowser.JXPhotoBrowser") as? UIViewController.Type else {
            print("❌ 无法找到 JXPhotoBrowser 类")
            return
        }
        
        // 创建 JXPhotoBrowser 实例
        let browser = browserClass.init()
        
        // 使用 KVC (Key-Value Coding) 设置属性
        // 因为是动态类型，无法直接访问属性，需要使用 setValue 方法
        
        // 1. 设置初始页码（从哪张图片开始显示）
        browser.setValue(initialIndex, forKey: "pageIndex")
        
        // 2. 设置数据源总数（总共有多少张图片）
        // numberOfItems 是一个闭包，返回图片总数
        let numberOfItemsClosure: () -> Int = { [imageNames] in
            return imageNames.count
        }
        browser.setValue(numberOfItemsClosure, forKey: "numberOfItems")
        
        // 3. 设置 Cell 类型
        // cellClassAtIndex 是一个闭包，根据索引返回对应的 Cell 类
        // 这里统一使用 JXPhotoBrowserImageCell 来显示图片
        let cellClassClosure: (Int) -> AnyClass = { _ in
            // 动态获取 JXPhotoBrowserImageCell 类
            guard let cellClass = NSClassFromString("JXPhotoBrowser.JXPhotoBrowserImageCell") else {
                fatalError("❌ 无法找到 JXPhotoBrowserImageCell 类")
            }
            return cellClass
        }
        browser.setValue(cellClassClosure, forKey: "cellClassAtIndex")
        
        // 4. 设置 Cell 数据刷新回调
        // reloadCellAtIndex 是一个闭包，用于配置每个 Cell 的数据
        // 这是最核心的部分，负责加载和显示图片
        let reloadClosure: (Any) -> Void = { [imageNames] context in
            // context 是一个元组，包含 (cell, index, currentIndex)
            // 使用 Mirror 反射来提取元组中的值
            let mirror = Mirror(reflecting: context)
            
            // 提取 cell 对象
            guard let cell = mirror.children.first(where: { $0.label == ".0" })?.value else {
                print("❌ 无法获取 cell")
                return
            }
            
            // 提取当前索引
            guard let index = mirror.children.first(where: { $0.label == ".1" })?.value as? Int else {
                print("❌ 无法获取 index")
                return
            }
            
            // 确保索引在有效范围内
            guard index < imageNames.count else {
                print("❌ 索引越界: \(index)")
                return
            }
            
            // 获取当前图片的文件名
            let imageName = imageNames[index]
            
            // 使用 ImageLoader 加载图片
            if let uiImage = ImageLoader.loadUIImage(name: imageName) {
                // 通过 KVC 设置 Cell 的 imageView.image 属性
                // JXPhotoBrowserImageCell 内部有一个 imageView 用于显示图片
                if let imageView = (cell as AnyObject).value(forKey: "imageView") {
                    (imageView as AnyObject).setValue(uiImage, forKey: "image")
                }
            } else {
                print("⚠️ 无法加载图片: \(imageName)")
            }
        }
        browser.setValue(reloadClosure, forKey: "reloadCellAtIndex")
        
        // 5. 设置页码改变回调（可选）
        // 当用户滑动切换图片时，这个回调会被触发
        let pageChangedClosure: (Int) -> Void = { index in
            print("📷 当前显示第 \(index + 1) 张图片")
        }
        browser.setValue(pageChangedClosure, forKey: "didChangedPageIndex")
        
        // 6. 设置关闭回调
        // 当用户关闭浏览器时，更新 isPresented 状态
        let dismissClosure: (Any) -> Void = { [isPresented] _ in
            // 使用 DispatchQueue.main.async 确保在主线程更新状态
            DispatchQueue.main.async {
                // 这里不能直接修改 isPresented，因为它是值类型
                // 需要通过父视图的 Binding 来更新
            }
        }
        browser.setValue(dismissClosure, forKey: "didDismiss")
        
        // 7. 显示浏览器
        // 使用 present 方式全屏显示
        browser.modalPresentationStyle = .fullScreen
        viewController.present(browser, animated: true) {
            print("✅ 图片浏览器已显示")
        }
    }
    
    /// 创建协调器（可选）
    /// 协调器用于处理委托回调等
    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented)
    }
    
    // MARK: - Coordinator
    
    /// 协调器类
    /// 用于处理 UIKit 和 SwiftUI 之间的通信
    class Coordinator: NSObject {
        @Binding var isPresented: Bool
        
        init(isPresented: Binding<Bool>) {
            _isPresented = isPresented
        }
        
        /// 当浏览器关闭时调用
        func browserDidDismiss() {
            isPresented = false
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
            .sheet(isPresented: $showBrowser) {
                PhotoBrowserWrapper(
                    isPresented: $showBrowser,
                    imageNames: ["avatar1.png", "avatar2.png"],
                    initialIndex: 0
                )
            }
        }
    }
    
    return PreviewWrapper()
}

