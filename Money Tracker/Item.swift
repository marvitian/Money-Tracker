//
//  Item.swift
//  Money Tracker
//
//  Created by Mario Ianniello on 2025-11-04.
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
