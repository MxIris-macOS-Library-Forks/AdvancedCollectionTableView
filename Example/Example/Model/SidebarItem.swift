//
//  SidebarItem.swift
//  
//
//  Created by Florian Zand on 22.06.23.
//

import Foundation
import FZSwiftUtils

public struct SidebarItem: Hashable, Identifiable {
    public let id = UUID()
    public let title: String
    public let symbolName: String
    
    public static var sampleItems: [SidebarItem] {
        [SidebarItem(title: "Person", symbolName: "person"),
         SidebarItem(title: "Photo", symbolName: "photo"),
         SidebarItem(title: "Video", symbolName: "film"),
        ]
    }
    
    public static var moreSampleItems: [SidebarItem] {
        [SidebarItem(title: "Table", symbolName: "table"),
         SidebarItem(title: "Collection", symbolName: "square.grid.3x3"),
        ]
    }
}
