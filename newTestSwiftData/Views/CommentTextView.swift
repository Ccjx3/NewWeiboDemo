//
//  CommentTextView.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/29.
//

import SwiftUI
import UIKit

/// UITextView 的 SwiftUI 封装
/// 用于实现自动弹出键盘和滑动收起键盘的功能
struct CommentTextView: UIViewRepresentable {
    /// 双向绑定的文本内容
    @Binding var text: String
    
    /// 是否在视图出现时自动开始编辑
    let beginEdittingOnAppear: Bool
    
    // MARK: - UIViewRepresentable 协议方法
    
    /// 创建协调器，处理 UIKit 与 SwiftUI 的通信
    func makeCoordinator() -> Coordinator {
        Coordinator { newText in
            self.text = newText
        }
    }
    
    /// 创建并配置 UITextView
    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        
        // 外观配置
        view.backgroundColor = .systemGray6
        view.font = .systemFont(ofSize: 18)
        view.textContainerInset = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        
        // 委托设置
        view.delegate = context.coordinator
        view.text = text
        
        // ⭐ 键盘行为配置（核心功能）
        view.keyboardDismissMode = .interactive  // 交互式收起键盘
        view.alwaysBounceVertical = true         // 始终允许垂直弹跳
        view.isScrollEnabled = true              // 启用滚动
        
        // 自动弹出键盘
        if beginEdittingOnAppear {
            view.becomeFirstResponder()
        }
        
        return view
    }
    
    /// 更新 UITextView 状态
    func updateUIView(_ uiView: UITextView, context: Context) {
        // 只在首次且满足条件时弹出键盘
        if beginEdittingOnAppear,
           !context.coordinator.disBecomeFirstResponder,
           uiView.window != nil,
           !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
            context.coordinator.disBecomeFirstResponder = true
        }
    }
    
    // MARK: - Coordinator 协调器
    
    /// 协调器类 - 作为 UIKit 和 SwiftUI 之间的桥梁
    class Coordinator: NSObject, UITextViewDelegate {
        /// 文本更新闭包
        var textChanged: (String) -> Void
        
        /// 是否已经成为第一响应者（防止重复触发）
        var disBecomeFirstResponder: Bool = false
        
        init(textChanged: @escaping (String) -> Void) {
            self.textChanged = textChanged
        }
        
        /// 监听文本变化，实时同步到 SwiftUI
        func textViewDidChange(_ textView: UITextView) {
            textChanged(textView.text ?? "")
        }
    }
}

