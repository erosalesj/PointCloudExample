//
//  Item.swift
//  PointCloudExample
//
//  Created by cisstudent on 11/10/25.
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
