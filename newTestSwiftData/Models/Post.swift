//
//  Post.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/23.
//

import Foundation
import SwiftData

/// Post 数据模型
/// 代表一条社交媒体帖子，包含用户信息、内容、图片和互动数据
@Model
final class Post {
    /// 帖子唯一标识符
    var id: Int
    
    /// 用户头像文件名（存储在 Resources 文件夹中）
    /// SwiftData 中图片通常存储为 String（文件名或 URL），而不是直接存储图片数据
    /// 这样可以节省数据库空间，提高性能
    var avatar: String
    
    /// 是否为 VIP 用户
    var vip: Bool
    
    /// 用户名称
    var name: String
    
    /// 发布日期字符串（格式：yyyy-MM-dd HH:mm）
    /// 注意：也可以存储为 Date 类型，但为了与 JSON 保持一致，这里使用 String
    var date: String
    
    /// 是否已关注该用户
    var isFollowed: Bool
    
    /// 帖子文本内容
    var text: String
    
    /// 帖子图片文件名数组
    /// SwiftData 支持存储数组类型，图片文件名存储在数组中
    /// 实际图片文件存储在 Resources 文件夹，这里只存储文件名引用
    var images: [String]
    
    /// 评论数量
    var commentCount: Int
    
    /// 点赞数量
    var likeCount: Int
    
    /// 是否已点赞
    var isLiked: Bool
    
    /// 初始化方法
    init(
        id: Int,
        avatar: String,
        vip: Bool,
        name: String,
        date: String,
        isFollowed: Bool,
        text: String,
        images: [String],
        commentCount: Int,
        likeCount: Int,
        isLiked: Bool
    ) {
        self.id = id
        self.avatar = avatar
        self.vip = vip
        self.name = name
        self.date = date
        self.isFollowed = isFollowed
        self.text = text
        self.images = images
        self.commentCount = commentCount
        self.likeCount = likeCount
        self.isLiked = isLiked
    }
    
    /// 从 JSON 字典创建 Post 实例
    /// 用于从 JSON 文件加载数据
    convenience init?(from json: [String: Any]) {
        guard let id = json["id"] as? Int,
              let avatar = json["avatar"] as? String,
              let vip = json["vip"] as? Bool,
              let name = json["name"] as? String,
              let date = json["date"] as? String,
              let isFollowed = json["isFollowed"] as? Bool,
              let text = json["text"] as? String,
              let images = json["images"] as? [String],
              let commentCount = json["commentCount"] as? Int,
              let likeCount = json["likeCount"] as? Int,
              let isLiked = json["isLiked"] as? Bool else {
            return nil
        }
        
        self.init(
            id: id,
            avatar: avatar,
            vip: vip,
            name: name,
            date: date,
            isFollowed: isFollowed,
            text: text,
            images: images,
            commentCount: commentCount,
            likeCount: likeCount,
            isLiked: isLiked
        )
    }
    
    /// 转换为 JSON 字典
    /// 用于保存数据到 JSON 文件
    func toJSON() -> [String: Any] {
        return [
            "id": id,
            "avatar": avatar,
            "vip": vip,
            "name": name,
            "date": date,
            "isFollowed": isFollowed,
            "text": text,
            "images": images,
            "commentCount": commentCount,
            "likeCount": likeCount,
            "isLiked": isLiked
        ]
    }
}
