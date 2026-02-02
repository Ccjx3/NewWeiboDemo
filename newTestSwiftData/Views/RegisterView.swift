//
//  RegisterView.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/29.
//

import SwiftUI

/// 注册视图
struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var email: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var isConfirmPasswordVisible: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @State private var showSuccessHUD: Bool = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case username, email, password, confirmPassword
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 渐变背景
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.15, green: 0.4, blue: 0.6),
                        Color(red: 0.25, green: 0.5, blue: 0.7)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // 装饰性圆形
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 280, height: 280)
                    .blur(radius: 50)
                    .offset(x: 160, y: -280)
                
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 220, height: 220)
                    .blur(radius: 40)
                    .offset(x: -140, y: 380)
                
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
                                    .frame(width: 90, height: 90)
                                
                                Image(systemName: "person.badge.plus.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                            }
                            
                            Text("创建账号")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("加入我们，开启精彩旅程")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.top, 50)
                        .padding(.bottom, 40)
                        
                        // 注册表单
                        VStack(spacing: 18) {
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
                                            focusedField = .email
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
                            
                            // 邮箱输入框
                            VStack(alignment: .leading, spacing: 8) {
                                Text("邮箱")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(.leading, 4)
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "envelope.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white.opacity(0.7))
                                        .frame(width: 24)
                                    
                                    TextField("请输入邮箱", text: $email)
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .accentColor(.white)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .focused($focusedField, equals: .email)
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
                                                .stroke(focusedField == .email ? Color.white.opacity(0.5) : Color.clear, lineWidth: 2)
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
                                            .submitLabel(.next)
                                            .onSubmit {
                                                focusedField = .confirmPassword
                                            }
                                    } else {
                                        SecureField("请输入密码", text: $password)
                                            .font(.system(size: 16))
                                            .foregroundColor(.white)
                                            .accentColor(.white)
                                            .focused($focusedField, equals: .password)
                                            .submitLabel(.next)
                                            .onSubmit {
                                                focusedField = .confirmPassword
                                            }
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
                            
                            // 确认密码输入框
                            VStack(alignment: .leading, spacing: 8) {
                                Text("确认密码")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(.leading, 4)
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white.opacity(0.7))
                                        .frame(width: 24)
                                    
                                    if isConfirmPasswordVisible {
                                        TextField("请再次输入密码", text: $confirmPassword)
                                            .font(.system(size: 16))
                                            .foregroundColor(.white)
                                            .accentColor(.white)
                                            .focused($focusedField, equals: .confirmPassword)
                                            .submitLabel(.done)
                                    } else {
                                        SecureField("请再次输入密码", text: $confirmPassword)
                                            .font(.system(size: 16))
                                            .foregroundColor(.white)
                                            .accentColor(.white)
                                            .focused($focusedField, equals: .confirmPassword)
                                            .submitLabel(.done)
                                    }
                                    
                                    Button(action: {
                                        isConfirmPasswordVisible.toggle()
                                    }) {
                                        Image(systemName: isConfirmPasswordVisible ? "eye.fill" : "eye.slash.fill")
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
                                                .stroke(focusedField == .confirmPassword ? Color.white.opacity(0.5) : Color.clear, lineWidth: 2)
                                        )
                                )
                            }
                            
                            // 注册按钮
                            Button(action: {
                                // 判空验证
                                if username.trimmingCharacters(in: .whitespaces).isEmpty {
                                    errorMessage = "用户名不能为空"
                                    showError = true
                                    return
                                }
                                
                                if email.trimmingCharacters(in: .whitespaces).isEmpty {
                                    errorMessage = "邮箱不能为空"
                                    showError = true
                                    return
                                }
                                
                                if password.trimmingCharacters(in: .whitespaces).isEmpty {
                                    errorMessage = "密码不能为空"
                                    showError = true
                                    return
                                }
                                
                                if confirmPassword.trimmingCharacters(in: .whitespaces).isEmpty {
                                    errorMessage = "确认密码不能为空"
                                    showError = true
                                    return
                                }
                                
                                if password != confirmPassword {
                                    errorMessage = "两次密码输入不一致"
                                    showError = true
                                    return
                                }
                                
                                // 添加触觉反馈
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                
                                // 调用 SwiftData 注册服务
                                SwiftDataAuthService.shared.register(username: username, password: password, email: email) { result in
                                    switch result {
                                    case .success(let response):
                                        print("✅ 注册成功：\(response.user.username)")
                                        
                                        // 保存注册信息到 AuthManager
                                        AuthManager.shared.register(response: response)
                                        
                                        // 显示注册成功提示
                                        showSuccessHUD = true
    
                                        // 1.5秒后返回 LoginView
                                        //and print 数据库中用户账号密码的列表数据
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                            print("\n🔍 查询认证数据库信息：")
                                            SwiftDataAuthService.shared.printAllUsers()
                                            //返回LoginView
                                            showSuccessHUD = false
                                            dismiss()
                                        }
                                        
                                    case .failure(let error):
                                        errorMessage = error.message
                                        showError = true
                                    }
                                }
                            }) {
                                HStack {
                                    Text("注册")
                                        .font(.system(size: 18, weight: .semibold))
                                    
                                    Image(systemName: "checkmark.circle")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(Color(red: 0.15, green: 0.4, blue: 0.6))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                                )
                            }
                            .padding(.top, 12)
                            
                            // 登录提示
                            HStack(spacing: 4) {
                                Text("已有账号？")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Button(action: {
                                    dismiss()
                                }) {
                                    Text("立即登录")
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
            .overlay {
                // 注册成功提示
                if showSuccessHUD {
                    RegisterSuccessHUDView(isVisible: showSuccessHUD)
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

/// 注册成功 HUD 视图
struct RegisterSuccessHUDView: View {
    let isVisible: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)
            
            Text("注册成功")
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
    RegisterView()
}

