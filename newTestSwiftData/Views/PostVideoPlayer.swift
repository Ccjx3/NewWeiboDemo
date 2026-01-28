//
//  PostVideoPlayer.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/27.
//

import SwiftUI
import AVKit
import Combine

/// 视频播放器状态管理器
class VideoPlayerManager: ObservableObject {
    @Published var isPlaying = false
    @Published var isLoading = true
    @Published var loadError = false
    @Published var isMuted = true  // 添加静音状态，默认静音
    var cancellables = Set<AnyCancellable>()
    
    deinit {
        cancellables.removeAll()
    }
}

/// 帖子视频播放器视图
/// 使用 AVKit 的 VideoPlayer 实现类似微博、朋友圈的视频播放效果
struct PostVideoPlayer: View {
    let videoUrl: String
    @State private var player: AVPlayer?
    @State private var showFullScreen = false  // 全屏播放状态
    @StateObject private var manager = VideoPlayerManager()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景色
                Color.black
                
                if manager.loadError {
                    // 加载失败提示
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.7))
                        Text("视频加载失败")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                        Text(videoUrl)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else if let player = player {
                    // 视频播放器 - 使用原生控制
                    VideoPlayer(player: player)
                        .onAppear {
                            // 设置播放器循环播放
                            NotificationCenter.default.addObserver(
                                forName: .AVPlayerItemDidPlayToEndTime,
                                object: player.currentItem,
                                queue: .main
                            ) { _ in
                                player.seek(to: .zero)
                                player.play()
                            }
                        }
                        .overlay {
                            // 加载指示器
                            if manager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                            }
                        }
                        .overlay {
                            // 双击手势检测区域（透明覆盖层）
                            // 使用 allowsHitTesting(false) 让静音按钮可以接收点击
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture(count: 2) {
                                    print("🎬 双击视频，进入全屏播放")
                                    withAnimation {
                                        showFullScreen = true
                                    }
                                }
                                .allowsHitTesting(true)
                        }
                        .overlay(alignment: .topTrailing) {
                            // 自定义静音按钮 - 放在最上层
                            Button(action: {
                                manager.isMuted.toggle()
                                player.isMuted = manager.isMuted
                                print("🔊 用户切换静音状态: \(manager.isMuted ? "静音" : "有声")")
                            }) {
                                Image(systemName: manager.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            .padding(12)
                            .zIndex(1)  // 确保在最上层
                        }

                } else {
                    // 初始加载状态
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .cornerRadius(12)
            .onAppear {
                loadVideo()
            }
            .onDisappear {
                // 清理播放器
                player?.pause()
                player = nil
            }
            .fullScreenCover(isPresented: $showFullScreen) {
                // 全屏播放器 - 使用 AVKit 原生播放器
                if let player = player {
                    FullScreenVideoPlayer(player: player, isPresented: $showFullScreen)
                        .ignoresSafeArea()
                }
            }
        }
    }
    
    /// 加载视频
    private func loadVideo() {
        // 构建完整的视频 URL - 使用 NetworkManager 的统一基础 URL
        let fullURL: URL?
        
        if videoUrl.hasPrefix("http://") || videoUrl.hasPrefix("https://") {
            // 已经是完整 URL
            fullURL = URL(string: videoUrl)
        } else {
            // 使用 GitHub 资源库的基础 URL
            let baseURL = NetworkAPIBaseURL
            fullURL = URL(string: baseURL + videoUrl)
        }
        
        guard let url = fullURL else {
            print("❌ 无效的视频 URL: \(videoUrl)")
            manager.loadError = true
            manager.isLoading = false
            return
        }
        
        print("📹 加载视频: \(url.absoluteString)")
        
        // 创建播放器
        let playerItem = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: playerItem)
        
        // 设置播放器
        self.player = newPlayer
        
        // 设置默认静音
        newPlayer.isMuted = true
        print("🔇 初始化：设置默认静音")
        
        // 监听播放器状态
        playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak manager] status in
                guard let manager = manager else { return }
                switch status {
                case .readyToPlay:
                    print("✅ 视频准备就绪")
                    manager.isLoading = false
                    manager.loadError = false
                    // 自动播放
                    newPlayer.play()
                    manager.isPlaying = true
                    // 同步当前静音状态到 manager（而不是强制覆盖）
                    manager.isMuted = newPlayer.isMuted
                    print("🔇 当前静音状态: \(newPlayer.isMuted ? "静音" : "有声")")
                case .failed:
                    print("❌ 视频加载失败: \(playerItem.error?.localizedDescription ?? "未知错误")")
                    if let error = playerItem.error {
                        print("❌ 错误详情: \(error)")
                    }
                    manager.isLoading = false
                    manager.loadError = true
                case .unknown:
                    print("⏳ 视频加载中...")
                @unknown default:
                    break
                }
            }
            .store(in: &manager.cancellables)
        
        // 监听 isMuted 属性变化，实现双向绑定
        newPlayer.publisher(for: \.isMuted)
            .receive(on: DispatchQueue.main)
            .sink { [weak manager] isMuted in
                print("🔊 播放器静音状态变化: \(isMuted ? "静音" : "有声")")
                // 同步到 manager，让自定义按钮图标也能更新
                manager?.isMuted = isMuted
            }
            .store(in: &manager.cancellables)
        
        // 监听 volume 属性变化，用于调试
        newPlayer.publisher(for: \.volume)
            .receive(on: DispatchQueue.main)
            .sink { volume in
                print("🔊 音量变化: \(volume)")
            }
            .store(in: &manager.cancellables)
    }
}

/// 简化版视频播放器 - 使用系统默认控制栏
struct SimpleVideoPlayer: View {
    let videoUrl: String
    @State private var player: AVPlayer?
    @State private var isLoading = true  // 添加加载状态
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                
                if let player = player {
                    VideoPlayer(player: player)
                        .onAppear {
                            // 循环播放
                            NotificationCenter.default.addObserver(
                                forName: .AVPlayerItemDidPlayToEndTime,
                                object: player.currentItem,
                                queue: .main
                            ) { _ in
                                player.seek(to: .zero)
                                player.play()
                            }
                            // 自动播放
                            player.play()
                        }
                        .overlay {
                            // 加载指示器
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                            }
                        }
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .cornerRadius(12)
            .onAppear {
                loadVideo()
            }
            .onDisappear {
                player?.pause()
                player = nil
            }
        }
    }
    
    private func loadVideo() {
        // 构建完整的视频 URL
        let fullURL: URL?
        
        if videoUrl.hasPrefix("http://") || videoUrl.hasPrefix("https://") {
            fullURL = URL(string: videoUrl)
        } else {
            // 使用 GitHub 资源库的基础 URL
            let baseURL = NetworkAPIBaseURL
            fullURL = URL(string: baseURL + videoUrl)
        }
        
        guard let url = fullURL else {
            print("❌ 无效的视频 URL: \(videoUrl)")
            isLoading = false
            return
        }
        
        print("📹 加载视频: \(url.absoluteString)")
        let playerItem = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: playerItem)
        
        // 设置播放器
        player = newPlayer
        
        // 不设置静音，让原生控制栏完全控制
        print("📹 播放器已创建，使用原生控制栏")
        
        // 监听播放器状态
        playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [self] status in
                switch status {
                case .readyToPlay:
                    print("✅ 视频准备就绪")
                    isLoading = false
                case .failed:
                    print("❌ 视频加载失败: \(playerItem.error?.localizedDescription ?? "未知错误")")
                    isLoading = false
                case .unknown:
                    print("⏳ 视频加载中...")
                @unknown default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // 监听 isMuted 属性变化，用于调试
        newPlayer.publisher(for: \.isMuted)
            .receive(on: DispatchQueue.main)
            .sink { isMuted in
                print("🔊 静音状态变化: \(isMuted ? "静音" : "有声")")
            }
            .store(in: &cancellables)
        
        // 监听 volume 属性变化，用于调试
        newPlayer.publisher(for: \.volume)
            .receive(on: DispatchQueue.main)
            .sink { volume in
                print("🔊 音量变化: \(volume)")
            }
            .store(in: &cancellables)
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}

/// 全屏视频播放器 - 使用 SwiftUI 包装 AVKit 并添加自定义控制
struct FullScreenVideoPlayer: View {
    let player: AVPlayer
    @Binding var isPresented: Bool
    @State private var isMuted: Bool
    
    init(player: AVPlayer, isPresented: Binding<Bool>) {
        self.player = player
        self._isPresented = isPresented
        // 初始化时获取播放器的静音状态
        self._isMuted = State(initialValue: player.isMuted)
    }
    
    var body: some View {
        ZStack {
            // AVKit 原生播放器
            FullScreenAVPlayerViewController(player: player, isPresented: $isPresented)
                .ignoresSafeArea()
            
            // 自定义静音按钮 - 覆盖在右上角
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        isMuted.toggle()
                        player.isMuted = isMuted
                        print("🔊 全屏模式切换静音状态: \(isMuted ? "静音" : "有声")")
                    }) {
                        Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .padding(16)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .padding(.top, 60)  // 避开状态栏和原生控制按钮
                    .padding(.trailing, 20)
                }
                
                Spacer()
            }
        }
        .onAppear {
            // 同步当前静音状态
            isMuted = player.isMuted
            print("🎬 全屏播放器打开，当前静音状态: \(isMuted ? "静音" : "有声")")
        }
    }
}

/// UIKit 包装的 AVPlayerViewController
struct FullScreenAVPlayerViewController: UIViewControllerRepresentable {
    let player: AVPlayer
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        controller.allowsPictureInPicturePlayback = true
        
        // 设置代理以监听关闭事件
        context.coordinator.playerViewController = controller
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // 不需要更新
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented)
    }
    
    class Coordinator: NSObject {
        @Binding var isPresented: Bool
        weak var playerViewController: AVPlayerViewController?
        
        init(isPresented: Binding<Bool>) {
            _isPresented = isPresented
        }
    }
    
    static func dismantleUIViewController(_ uiViewController: AVPlayerViewController, coordinator: Coordinator) {
        // 清理资源
        uiViewController.player = nil
    }
}

#Preview {
    PostVideoPlayer(videoUrl: "20260126_QoRwhwPQD.mp4")
        .frame(height: 300)
        .padding()
}

