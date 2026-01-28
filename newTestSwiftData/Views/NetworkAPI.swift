//
//  NetworkAPI.swift
//  NetworkDemo
//
//  Created by xiaoyouxinqing on 5/5/20.
//  Copyright © 2020 xiaoyouxinqing. All rights reserved.
//

import Foundation

/// 帖子列表响应模型
/// 用于解析网络请求返回的 JSON 数据
struct PostListResponse: Codable {
    let list: [PostData]
}

/// 帖子数据模型（用于网络请求）
/// 与 SwiftData 的 Post 模型分离，遵循单一职责原则
struct PostData: Codable {
    let id: Int
    let avatar: String
    let vip: Bool
    let name: String
    let date: String
    let isFollowed: Bool
    let text: String
    let images: [String]
    let commentCount: Int
    let likeCount: Int
    let isLiked: Bool
    let videoUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id, avatar, vip, name, date, isFollowed, text, images, commentCount, likeCount, isLiked
        case videoUrl = "video_url"
    }
}

/// 网络 API 接口
/// 提供获取帖子列表和创建帖子的功能
class NetworkAPI {
    /// 获取推荐帖子列表
    /// - Parameter completion: 完成回调，返回 PostListResponse 或错误
    static func recommendPostList(completion: @escaping (Result<PostListResponse, Error>) -> Void) {
        NetworkManager.shared.requestGet(path: "PostListData_recommend_2.json", parameters: nil) { result in
            switch result {
            case let .success(data):
                let parseResult: Result<PostListResponse, Error> = self.parseData(data)
                completion(parseResult)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    /// 获取热门帖子列表
    /// - Parameter completion: 完成回调，返回 PostListResponse 或错误
    static func hotPostList(completion: @escaping (Result<PostListResponse, Error>) -> Void) {
        NetworkManager.shared.requestGet(path: "PostListData_hot_2.json", parameters: nil) { result in
            switch result {
            case let .success(data):
                let parseResult: Result<PostListResponse, Error> = self.parseData(data)
                completion(parseResult)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    /// 创建新帖子
    /// - Parameters:
    ///   - text: 帖子文本内容
    ///   - completion: 完成回调，返回 PostData 或错误
    static func createPost(text: String, completion: @escaping (Result<PostData, Error>) -> Void) {
        NetworkManager.shared.requestPost(path: "createpost", parameters: ["text": text]) { result in
            switch result {
            case let .success(data):
                let parseResult: Result<PostData, Error> = self.parseData(data)
                completion(parseResult)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    /// 解析 JSON 数据
    /// - Parameter data: 原始数据
    /// - Returns: 解析结果（成功或失败）
    private static func parseData<T: Decodable>(_ data: Data) -> Result<T, Error> {
        do {
            let decodedData = try JSONDecoder().decode(T.self, from: data)
            return .success(decodedData)
        } catch {
            print("❌ JSON 解析失败: \(error)")
            let customError = NSError(
                domain: "NetworkAPIError",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "无法解析数据: \(error.localizedDescription)"]
            )
            return .failure(customError)
        }
    }
}
