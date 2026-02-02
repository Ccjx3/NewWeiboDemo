//
//  HighlightedText.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/30.
//

import SwiftUI

/// 高亮文本组件 - 将匹配的关键词用黄色背景高亮显示
struct HighlightedText: View {
    let text: String
    let keyword: String
    let font: Font
    let highlightColor: Color
    
    init(
        text: String,
        keyword: String,
        font: Font = .body,
        highlightColor: Color = Color.yellow.opacity(0.6)
    ) {
        self.text = text
        self.keyword = keyword
        self.font = font
        self.highlightColor = highlightColor
    }
    
    var body: some View {
        if keyword.isEmpty {
            // 如果没有关键词，直接显示原文本
            Text(text)
                .font(font)
        } else {
            // 使用 AttributedString 实现高亮
            Text(highlightedAttributedString())
                .font(font)
        }
    }
    
    /// 生成带高亮的 AttributedString
    private func highlightedAttributedString() -> AttributedString {
        var attributedString = AttributedString(text)
        
        // 不区分大小写地查找所有匹配位置
        let lowercasedText = text.lowercased()
        let lowercasedKeyword = keyword.lowercased()
        
        var searchRange = lowercasedText.startIndex..<lowercasedText.endIndex
        
        while let range = lowercasedText.range(of: lowercasedKeyword, range: searchRange) {
            // 将 String.Index 转换为 AttributedString.Index
            if let attributedRange = Range<AttributedString.Index>(range, in: attributedString) {
                // 设置黄色背景
                attributedString[attributedRange].backgroundColor = highlightColor
                // 可选：设置粗体
                attributedString[attributedRange].font = .body.bold()
            }
            
            // 继续查找下一个匹配
            searchRange = range.upperBound..<lowercasedText.endIndex
            if searchRange.isEmpty {
                break
            }
        }
        
        return attributedString
    }
}



#Preview {
    VStack(alignment: .leading, spacing: 20) {
        Text("高亮文本示例")
            .font(.title2)
            .bold()
        
        Divider()
        
        VStack(alignment: .leading, spacing: 12) {
            Text("原文本：")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("这是一个测试文本，包含多个测试关键词。Test 和 test 都会被高亮。")
                .font(.body)
            
            Text("搜索关键词：test")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
            
            HighlightedText(
                text: "这是一个测试文本，包含多个测试关键词。Test 和 test 都会被高亮。",
                keyword: "test"
            )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        
        VStack(alignment: .leading, spacing: 12) {
            Text("示例 2：")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HighlightedText(
                text: "SwiftUI 是一个很棒的框架，SwiftUI 让开发变得简单。",
                keyword: "SwiftUI",
                font: .headline
            )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        
        Spacer()
    }
    .padding()
}

