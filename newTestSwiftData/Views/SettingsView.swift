//
//  SettingsView.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/29.
//

import SwiftUI

/// 设置视图
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notificationsEnabled = true
    @State private var darkModeEnabled = false
    @State private var autoPlayVideos = true
    
    var body: some View {
        NavigationView {
            List {
                // 通用设置
                Section {
                    SettingsToggleRow(
                        icon: "bell.fill",
                        iconColor: .orange,
                        title: "推送通知",
                        isOn: $notificationsEnabled
                    )
                    
                    SettingsToggleRow(
                        icon: "moon.fill",
                        iconColor: .indigo,
                        title: "深色模式",
                        isOn: $darkModeEnabled
                    )
                    
                    SettingsToggleRow(
                        icon: "play.circle.fill",
                        iconColor: .green,
                        title: "自动播放视频",
                        isOn: $autoPlayVideos
                    )
                } header: {
                    Text("通用")
                }
                
                // 账号设置
                Section {
                    SettingsNavigationRow(
                        icon: "person.fill",
                        iconColor: .blue,
                        title: "账号管理",
                        action: {
                            print("账号管理")
                        }
                    )
                    
                    SettingsNavigationRow(
                        icon: "lock.fill",
                        iconColor: .red,
                        title: "隐私设置",
                        action: {
                            print("隐私设置")
                        }
                    )
                    
                    SettingsNavigationRow(
                        icon: "shield.fill",
                        iconColor: .purple,
                        title: "安全中心",
                        action: {
                            print("安全中心")
                        }
                    )
                } header: {
                    Text("账号与安全")
                }
                
                // 其他
                Section {
                    SettingsNavigationRow(
                        icon: "questionmark.circle.fill",
                        iconColor: .cyan,
                        title: "帮助与反馈",
                        action: {
                            print("帮助与反馈")
                        }
                    )
                    
                    SettingsNavigationRow(
                        icon: "doc.text.fill",
                        iconColor: .gray,
                        title: "关于我们",
                        action: {
                            print("关于我们")
                        }
                    )
                } header: {
                    Text("其他")
                }
                
                // 版本信息
                Section {
                    HStack {
                        Text("版本")
                            .foregroundColor(.primary)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

/// 设置开关行
struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(iconColor)
                    .frame(width: 28, height: 28)
                
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.system(size: 16))
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
    }
}

/// 设置导航行
struct SettingsNavigationRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(iconColor)
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SettingsView()
}

