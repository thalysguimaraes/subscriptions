//
//  Item.swift
//  Subscriptions
//
//  Created by Thalys Guimarães on 29/12/23.
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
