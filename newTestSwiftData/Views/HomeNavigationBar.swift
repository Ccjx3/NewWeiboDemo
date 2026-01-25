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
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // 左侧菜单按钮
            Button(action: {
                print("点击菜单按钮")
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
            
            Spacer()
            
            // 中间标签切换区域
            VStack(spacing: 8) {
                HStack(spacing: 0) {
                    Text("推荐")
                        .bold()
                        .frame(width: kLabelWidth, height: kButtonHeight)
                        .foregroundColor(leftPercent < 0.5 ? .blue : .gray)
                        .scaleEffect(leftPercent < 0.5 ? 1.05 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: leftPercent)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                self.leftPercent = 0
                            }
                        }
                    
                    Spacer()
                    
                    Text("热门")
                        .bold()
                        .frame(width: kLabelWidth, height: kButtonHeight)
                        .foregroundColor(leftPercent >= 0.5 ? .blue : .gray)
                        .scaleEffect(leftPercent >= 0.5 ? 1.05 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: leftPercent)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                self.leftPercent = 1
                            }
                        }
                }
                .font(.system(size: 20))
                .padding(.top, 5)
                
                // 指示器容器
                HStack(spacing: 0) {
                    // 推荐指示器
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .cyan]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 30, height: 4)
                        .opacity(leftPercent < 0.5 ? 1 : 0)
                        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: leftPercent)
                    
                    Spacer()
                    
                    // 热门指示器
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .cyan]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 30, height: 4)
                        .opacity(leftPercent >= 0.5 ? 1 : 0)
                        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: leftPercent)
                }
                .frame(width: kLabelWidth * 2 + 40)
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
