//
//  Item.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/23.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
