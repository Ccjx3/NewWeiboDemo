//
//  LoginView.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/29.
//

import SwiftUI

/// 登录视图
struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthManager.shared
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var showRegisterView: Bool = false
    @State private var showLoginSuccessHUD: Bool = false
    @State private var showUserView: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case username, password
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 渐变背景
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.2, blue: 0.45),
                        Color(red: 0.2, green: 0.3, blue: 0.6)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // 装饰性圆形
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 300, height: 300)
                    .blur(radius: 50)
                    .offset(x: -150, y: -300)
                
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 250, height: 250)
                    .blur(radius: 40)
                    .offset(x: 180, y: 400)
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Logo 区域
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.white.opacity(0.3), .white.opacity(0.1)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white)
                            }
                            
                            Text("欢迎回来")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("登录以继续使用")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.top, 60)
                        .padding(.bottom, 50)
                        
                        // 登录表单
                        VStack(spacing: 20) {
                            // 用户名输入框
                            VStack(alignment: .leading, spacing: 8) {
                                Text("用户名")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(.leading, 4)
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white.opacity(0.7))
                                        .frame(width: 24)
                                    
                                    TextField("请输入用户名", text: $username)
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .accentColor(.white)
                                        .focused($focusedField, equals: .username)
                                        .submitLabel(.next)
                                        .onSubmit {
                                            focusedField = .password
                                        }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white.opacity(0.15))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(focusedField == .username ? Color.white.opacity(0.5) : Color.clear, lineWidth: 2)
                                        )
                                )
                            }
                            
                            // 密码输入框
                            VStack(alignment: .leading, spacing: 8) {
                                Text("密码")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(.leading, 4)
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white.opacity(0.7))
                                        .frame(width: 24)
                                    
                                    if isPasswordVisible {
                                        TextField("请输入密码", text: $password)
                                            .font(.system(size: 16))
                                            .foregroundColor(.white)
                                            .accentColor(.white)
                                            .focused($focusedField, equals: .password)
                                            .submitLabel(.done)
                                    } else {
                                        SecureField("请输入密码", text: $password)
                                            .font(.system(size: 16))
                                            .foregroundColor(.white)
                                            .accentColor(.white)
                                            .focused($focusedField, equals: .password)
                                            .submitLabel(.done)
                                    }
                                    
                                    Button(action: {
                                        isPasswordVisible.toggle()
                                    }) {
                                        Image(systemName: isPasswordVisible ? "eye.fill" : "eye.slash.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white.opacity(0.15))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(focusedField == .password ? Color.white.opacity(0.5) : Color.clear, lineWidth: 2)
                                        )
                                )
                            }
                            
                            // 忘记密码
                            HStack {
                                Spacer()
                                Button(action: {
                                    print("忘记密码")
                                }) {
                                    Text("忘记密码？")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                }
                            }
                            .padding(.top, -8)
                            
                            // 登录按钮
                            Button(action: {
                                // 判空验证
                                if username.trimmingCharacters(in: .whitespaces).isEmpty {
                                    errorMessage = "用户名不能为空"
                                    showError = true
                                    return
                                }
                                
                                if password.trimmingCharacters(in: .whitespaces).isEmpty {
                                    errorMessage = "密码不能为空"
                                    showError = true
                                    return
                                }
                                
                                // 添加触觉反馈
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                
                                // 调用 SwiftData 登录服务
                                SwiftDataAuthService.shared.login(username: username, password: password) { result in
                                    switch result {
                                    case .success(let response):
                                        print("✅ 登录成功：\(response.user.username)")
                                        
                                        // 保存登录信息到 AuthManager
                                        authManager.login(response: response)
                                        
                                        // 显示登录成功弹窗
                                        showLoginSuccessHUD = true
                                        
                                        // 1.5秒后关闭弹窗并进入 UserView
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                            showLoginSuccessHUD = false
                                            dismiss()
                                            
                                            // 延迟一下再显示 UserView
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                showUserView = true
                                            }
                                        }
                                        
                                    case .failure(let error):
                                        errorMessage = error.message
                                        showError = true
                                    }
                                }
                            }) {
                                HStack {
                                    Text("登录")
                                        .font(.system(size: 18, weight: .semibold))
                                    
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(Color(red: 0.1, green: 0.2, blue: 0.45))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                                )
                            }
                            .padding(.top, 12)
                            
                            // 注册提示
                            HStack(spacing: 4) {
                                Text("还没有账号？")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Button(action: {
                                    showRegisterView = true
                                }) {
                                    Text("立即注册")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 32)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                            )
                    }
                }
            }
            .sheet(isPresented: $showRegisterView) {
                RegisterView()
            }
            .fullScreenCover(isPresented: $showUserView) {
                UserView()
            }
            .overlay {
                // 登录成功提示
                if showLoginSuccessHUD {
                    LoginSuccessHUDView(isVisible: showLoginSuccessHUD)
                }
            }
            .alert("提示", isPresented: $showError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
}

/// 登录成功 HUD 视图
struct LoginSuccessHUDView: View {
    let isVisible: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)
            
            Text("登录成功")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
        )
        .scaleEffect(isVisible ? 1 : 0.5)
        .opacity(isVisible ? 1 : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isVisible)
    }
}

#Preview {
    LoginView()
}

