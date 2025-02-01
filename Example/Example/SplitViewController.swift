//
//  SplitViewController.swift
//  Example
//
//  Created by Florian Zand on 20.01.25.
//

import Cocoa
import FZUIKit

class SplitViewController: NSSplitViewController {
    
    func swapSidebar() {
        splitViewItems[0].isCollapsed = true
        splitViewItems.swapAt(0, 2)
        splitViewItems[0].isCollapsed = false
    }
    
}
