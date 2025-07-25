//
//  Item.swift
//  NightreignTimer
//
//  Created by Tim OLeary on 6/24/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date = Date()

    init(timestamp: Date = Date()) {
        self.timestamp = timestamp
    }
}
