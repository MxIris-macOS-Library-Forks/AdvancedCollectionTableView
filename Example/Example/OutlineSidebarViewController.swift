//
//  OutlineSidebarViewController.swift
//
//
//  Created by Florian Zand on 19.01.23.
//

import AppKit
import AdvancedCollectionTableView

class OutlineSidebarViewController: NSViewController {
    typealias DataSource = OutlineViewDiffableDataSource<OutlineItem>
    typealias CellRegistration = NSTableView.CellRegistration<NSTableCellView, OutlineItem>

    @IBOutlet var outlineView: NSOutlineView!
    
    lazy var dataSource = DataSource(outlineView: outlineView, cellRegistration: cellRegistration)
    
    let cellRegistration = CellRegistration { tableCell, _, _, outlineItem in
        var configuration = tableCell.defaultContentConfiguration()
        configuration.text = outlineItem.title
        tableCell.contentConfiguration = configuration
    }

    override func viewDidLoad() {
        super.viewDidLoad()
                
        outlineView.dataSource = dataSource
        dataSource.applyGroupItemCellRegistration(cellRegistration)
                
        /// Enables reordering selected rows by dragging them.
        dataSource.reorderingHandlers.canReorder = { selectedItems, newParentItem in
            return selectedItems
        }
        
        /// Enables deleting selected items via backspace key.
        dataSource.deletingHandlers.canDelete = { selectedItems in
            return selectedItems
        }

        applySnapshot()
    }
        
    func applySnapshot() {
        var snapshot = dataSource.emptySnapshot()
        let rootItems: [OutlineItem] = ["Root 1", "Root 2", "Root 3", "Root 4", "Root 5"]
        snapshot.append(rootItems)
        rootItems.forEach { rootItem in
            let childItems = (1...5).map { OutlineItem("\(rootItem.title).\($0)") }
            snapshot.append(childItems, to: rootItem)
            childItems.forEach { childItem in
                let grandchildItems = (1...5).map { OutlineItem("\(childItem.title).\($0)") }
                snapshot.append(grandchildItems, to: childItem)
            }
        }
        dataSource.apply(snapshot, .withoutAnimation)
        dataSource.expand(rootItems)
    }
    
    @IBAction func segmentedPressed(_ segmentedControl: NSSegmentedControl) {
        (view.window?.contentViewController as? SplitViewController)?.swapSidebar()
        segmentedControl.selectedSegment = 1
    }
}
