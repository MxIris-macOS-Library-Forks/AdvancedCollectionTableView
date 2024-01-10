//
//  NSTableView+ReconfigurateRows.swift
//
//
//  Created by Florian Zand on 18.05.22.
//

import AppKit
import FZSwiftUtils

extension NSTableView {
    /**
     Updates the data for the rows at the indexes you specify, preserving the existing cells for the rows.

     To update the contents of existing (including prefetched) cells without replacing them with new cells, use this method instead of `reloadData(forRowIndexes:columnIndexes:)`. For optimal performance, choose to reconfigure rows instead of reloading rows unless you have an explicit need to replace the existing cell with a new cell.

     Your cell provider must dequeue the same type of cell for the provided index path, and must return the same existing cell for a given index path. Because this method reconfigures existing cells, the table view doesn’t call `prepareForReuse()` for each cell dequeued. If you need to return a different type of cell for an index path, use `reloadData(forRowIndexes:columnIndexes:)` instead.

     - Important: You can only reconfigurate cells that have been registered via  ``CellRegistration``, or by their class using ``register(_:)`` or ``register(_:forIdentifier:)``.

     - Parameters:
        - indexes: The indexes you want to update.
     */
    public func reconfigureRows(at indexes: IndexSet) {
        guard let delegate = delegate else { return }
        isReconfiguratingRows = true
        let columns = tableColumns
        for row in indexes {
            for (index, column) in columns.enumerated() {
                if view(atColumn: index, row: row, makeIfNecessary: false) != nil {
                    reconfigureIndexPath = IndexPath(item: row, section: index)
                    _ = delegate.tableView?(self, viewFor: column, row: row)
                }
            }
        }
        reconfigureIndexPath = nil
        isReconfiguratingRows = false
    }

    var reconfigureIndexPath: IndexPath? {
        get { getAssociatedValue(key: "reconfigureIndexPath", object: self, initialValue: nil) }
        set { set(associatedValue: newValue, key: "reconfigureIndexPath", object: self)
        }
    }

    var isReconfiguratingRows: Bool {
        get { getAssociatedValue(key: "isReconfiguratingRows", object: self, initialValue: false) }
        set { set(associatedValue: newValue, key: "isReconfiguratingRows", object: self)
        }
    }
}
