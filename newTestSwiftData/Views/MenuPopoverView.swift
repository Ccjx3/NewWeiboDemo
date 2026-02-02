//
//  MenuPopoverView.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/29.
//

import SwiftUI

/// 菜单弹窗视图
struct MenuPopoverView: View {
    @Binding var isPresented: Bool
    @Binding var showUserView: Bool
    @Binding var showSettings: Bool
    @Binding var showSearch: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 搜索选项
            MenuItemButton(
                icon: "magnifyingglass",
                title: "搜索",
                action: {
                    isPresented = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showSearch = true
                    }
                }
            )
            
            Divider()
                .padding(.horizontal, 12)
            
            // 用户主页选项
            MenuItemButton(
                icon: "person.circle.fill",
                title: "用户主页",
                action: {
                    isPresented = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showUserView = true
                    }
                }
            )
            
            Divider()
                .padding(.horizontal, 12)
            
            // 设置选项
            MenuItemButton(
                icon: "gearshape.fill",
                title: "设置",
                action: {
                    isPresented = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showSettings = true
                    }
                }
            )
        }
        .frame(width: 180)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)
        )
    }
}

/// 菜单项按钮
struct MenuItemButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // 添加触觉反馈
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                    .frame(width: 28)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(isPressed ? Color(.systemGray5) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

#Preview {
    MenuPopoverView(
        isPresented: .constant(true),
        showUserView: .constant(false),
        showSettings: .constant(false),
        showSearch: .constant(false)
    )
    .padding()
}

