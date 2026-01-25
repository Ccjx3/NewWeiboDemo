//
//  PostCellToolbarButton.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/25.
//

import SwiftUI

/// 帖子工具栏按钮组件
struct PostCellToolbarButton: View {
    let image: String
    let text: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: image)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                
                Text(text)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HStack {
        PostCellToolbarButton(image: "heart.fill", text: "1.2k", color: .red) {
            print("点赞")
        }
        
        PostCellToolbarButton(image: "message", text: "999", color: .black) {
            print("评论")
        }
        
        PostCellToolbarButton(image: "arrowshape.turn.up.right", text: "转发", color: .black) {
            print("转发")
        }
    }
}

