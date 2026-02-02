//
//  HomeNavigationBar.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/25.
//

import SwiftUI

private let kLabelWidth: CGFloat = 60
private let kButtonHeight: CGFloat = 24

/// 主页导航栏 - 支持推荐和热门切换
struct HomeNavigationBar: View {
    @Binding var leftPercent: CGFloat // 0 为推荐，1 为热门
    var onAddPost: () -> Void // 添加帖子回调
    
    @StateObject private var authManager = AuthManager.shared
    @State private var showMenuPopover = false
    @State private var showUserView = false
    @State private var showLoginView = false
    @State private var showSettings = false
    @State private var showSearch = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // 左侧菜单按钮
            Button(action: {
                // 添加触觉反馈
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                
                showMenuPopover = true
            }) {
                Image(systemName: "line.3.horizontal")
                    .resizable()
                    .scaledToFit()
                    .frame(width: kButtonHeight, height: kButtonHeight)
                    .padding(.horizontal, 15)
                    .padding(.top, 5)
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
            .popover(isPresented: $showMenuPopover, arrowEdge: .top) {
                MenuPopoverView(
                    isPresented: $showMenuPopover,
                    showUserView: $showUserView,
                    showSettings: $showSettings,
                    showSearch: $showSearch
                )
                .presentationCompactAdaptation(.popover)
            }
            .sheet(isPresented: $showUserView) {
                if authManager.isLoggedIn {
                    UserView()
                } else {
                    LoginView()
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .fullScreenCover(isPresented: $showSearch) {
                SearchView()
            }
            
            Spacer()
            
            // 中间标签切换区域
            VStack(spacing: 8) {
                HStack(spacing: 0) {
                    Text("推荐")
                        .bold()
                        .frame(width: kLabelWidth, height: kButtonHeight)
                        .foregroundColor(leftPercent < 0.5 ? .blue : .gray)
                        .scaleEffect(leftPercent < 0.5 ? 1.08 : 1.0)
                        .animation(.interpolatingSpring(stiffness: 300, damping: 25), value: leftPercent)
                        .onTapGesture {
                            // 添加触觉反馈
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            
                            withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
                                self.leftPercent = 0
                            }
                        }
                    
                    Spacer()
                    
                    Text("热门")
                        .bold()
                        .frame(width: kLabelWidth, height: kButtonHeight)
                        .foregroundColor(leftPercent >= 0.5 ? .blue : .gray)
                        .scaleEffect(leftPercent >= 0.5 ? 1.08 : 1.0)
                        .animation(.interpolatingSpring(stiffness: 300, damping: 25), value: leftPercent)
                        .onTapGesture {
                            // 添加触觉反馈
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            
                            withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
                                self.leftPercent = 1
                            }
                        }
                }
                .font(.system(size: 20))
                .padding(.top, 5)
                
                // 指示器容器 - 使用单个滑动指示器替代两个独立指示器
                GeometryReader { geometry in
                    let indicatorWidth: CGFloat = 30
                    let containerWidth = UIScreen.main.bounds.width * 0.5
                    // 计算左侧位置：左侧标签中心 - indicator宽度的一半
                    let leftPosition = kLabelWidth / 2 - indicatorWidth / 2
                    // 计算右侧位置：容器宽度 - 右侧标签宽度的一半 - indicator宽度的一半
                    let rightPosition = containerWidth - kLabelWidth / 2 - indicatorWidth / 2
                    let currentPosition = leftPosition + (rightPosition - leftPosition) * leftPercent
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .cyan]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: indicatorWidth, height: 4)
                        .offset(x: currentPosition)
                        .animation(.interpolatingSpring(stiffness: 300, damping: 30), value: leftPercent)
                }
                .frame(height: 4)
            }
            .frame(width: UIScreen.main.bounds.width * 0.5)
            
            Spacer()
            
            // 右侧添加按钮
            Button(action: onAddPost) {
                Image(systemName: "plus.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: kButtonHeight, height: kButtonHeight)
                    .padding(.horizontal, 15)
                    .padding(.top, 5)
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(width: UIScreen.main.bounds.width)
        .background(Color(.systemBackground))
    }
}

#Preview {
    HomeNavigationBar(leftPercent: .constant(0), onAddPost: {
        print("添加帖子")
    })
}
