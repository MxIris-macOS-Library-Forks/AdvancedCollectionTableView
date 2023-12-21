//
//  AdvanceTableViewDiffableDataSourceNew+.swift
//  TableDelegate
//
//  Created by Florian Zand on 01.08.23.
//

import AppKit
import FZUIKit
import FZQuicklook
import FZSwiftUtils
/**
 An advanced version or `NSTableViewDiffableDataSource`.
 
 It provides:
 - Reordering of items by enabling ``allowsReordering`` and optionally providing blocks to ``reorderingHandlers``.
 - Deleting of items by enabling  ``allowsDeleting`` and optionally providing blocks to ``deletionHandlers``.
 - Quicklooking of items via spacebar by providing elements conforming to ``QuicklookPreviewable``.
 - Handlers for selection of items ``selectionHandlers``.
 - Handlers for items that get hovered by mouse ``hoverHandlers``.
 - Providing a right click menu for selected items via ``menuProvider`` block.
 
 ```swift
 dataSource = AdvanceTableViewDiffableDataSource<Section, Element>(tableView: tableView, cellRegistration: cellRegistration)
 ```
 
 Then, you generate the current state of the data and display the data in the UI by constructing and applying a snapshot. For more information, see `NSDiffableDataSourceSnapshot`.
 
 - Important: Don’t change the dataSource or delegate on the table view after you configure it with a diffable data source. If the table view needs a new data source after you configure it initially, create and configure a new table view and diffable data source.
 */
public class AdvanceTableViewDiffableDataSource<Section, Item> : NSObject, NSTableViewDelegate, NSTableViewDataSource  where Section : Hashable & Identifiable, Item : Hashable & Identifiable {
    internal typealias Snapshot = NSDiffableDataSourceSnapshot<Section,  Item>
    internal typealias InternalSnapshot = NSDiffableDataSourceSnapshot<Section.ID,  Item.ID>
    internal typealias DataSoure = NSTableViewDiffableDataSource<Section.ID,  Item.ID>
    
    internal let tableView: NSTableView
    internal var dataSource: DataSoure!
    internal var currentSnapshot: Snapshot = Snapshot()
    internal var dragingRowIndexes = IndexSet()
    internal var sectionRowIndexes: [Int] = []
    internal var previousSelectedIDs: [Item.ID] = []
    internal var keyDownMonitor: Any? = nil
    internal var rightDownMonitor: NSEvent.Monitor? = nil
    internal var hoveredRowObserver: NSKeyValueObservation? = nil
    
    /// The closure that configures and returns the table view’s row views from the diffable data source.
    public var rowViewProvider: RowViewProvider? = nil {
        didSet {
            self.dataSource.rowViewProvider = self.rowViewProvider
        }
    }
    
    /// The closure that configures and returns the table view’s section header views from the diffable data source.
    public var sectionHeaderViewProvider: SectionHeaderViewProvider? = nil {
        didSet {
            if let sectionHeaderViewProvider = self.sectionHeaderViewProvider {
                dataSource.sectionHeaderViewProvider = { tableView, row, sectionID in
                    return sectionHeaderViewProvider(tableView, row, self.sections[id: sectionID]!)
                }
            } else {
                dataSource.sectionHeaderViewProvider = nil
            }
        }
    }
    
    /// A closure that configures and returns a row view for a table view from its diffable data source.
    public typealias RowViewProvider = (_ tableView: NSTableView, _ row: Int, _ identifier: AnyHashable) -> NSTableRowView
    
    /// A closure that configures and returns a section header view for a table view from its diffable data source.
    public typealias SectionHeaderViewProvider = (_ tableView: NSTableView, _ row: Int, _ section: Section) -> NSView
    
    /**     
     Right click menu provider.
     
     `items` provides:
     - if right-click on a selected item, all selected items,
     - or else if right-click on a non selected item, that item,
     - or else an empty array.
     
     When returning a menu to the `menuProvider`, the table view will display a menu on right click.
     */
    public var menuProvider: ((_ items: [Item]) -> NSMenu?)? = nil {
        didSet { setupRightDownMonitor() } }
    
    /**
     Provides an array of row actions to be attached to the specified edge of a table row and displayed when the user swipes horizontally across the row.
     */
    public var rowActionProvider: ((_ element: Item, _ edge: NSTableView.RowActionEdge) -> [NSTableViewRowAction])? = nil
    
    /// Handlers for selection of rows.
    public var selectionHandlers = SelectionHandlers()
    
    /// Handlers for deletion of rows.
    public var deletionHandlers = DeletionHandlers()
    
    /// Handlers for reordering of rows.
    public var reorderingHandlers = ReorderingHandlers()
    
    /// Handlers that get called whenever the mouse is hovering a row.
    public var hoverHandlers = HoverHandlers() {
        didSet { self.setupHoverObserving()} }
    
    /// Handlers for drag and drop of files from and to the table view.
    public var dragDropHandlers = DragdropHandlers()
    
    /// Handlers for table columns.
    public var columnHandlers = ColumnHandlers()
    
    /**
     A Boolean value that indicates whether users can reorder items in the table view when dragging them via mouse.
     
     If the value of this property is true (the default is false), users can reorder items in the table view.
     */
    public var allowsReordering: Bool = false
    
    /**
     A Boolean value that indicates whether users can delete items either via keyboard shortcut or right click menu.
     
     If the value of this property is true (the default is false), users can delete items.
     */
    public var allowsDeleting: Bool = false {
        didSet { self.setupKeyDownMonitor() }
    }
    
    /**
     Returns a representation of the current state of the data in the table view.
     
     A snapshot containing section and item identifiers in the order that they appear in the UI.
     */
    public func snapshot() -> NSDiffableDataSourceSnapshot<Section,  Item> {
        return currentSnapshot
    }
    
    /**
     Updates the UI to reflect the state of the data in the snapshot, optionally animating the UI changes.
     
     The system interrupts any ongoing item animations and immediately reloads the table view’s content.
     
     - Parameters:
     - snapshot: The snapshot that reflects the new state of the data in the table view.
     - option: Option how to apply the snapshot to the table view.
     - completion: A optional completion handlers which gets called after applying the snapshot.
     */
    public func apply(_ snapshot: NSDiffableDataSourceSnapshot<Section, Item>,_ option: NSDiffableDataSourceSnapshotApplyOption = .animated, completion: (() -> Void)? = nil) {
        let internalSnapshot = convertSnapshot(snapshot)
        self.currentSnapshot = snapshot
        self.updateSectionHeaderRows()
        dataSource.apply(internalSnapshot, option, completion: completion)
    }
    
    internal func convertSnapshot(_ snapshot: Snapshot) -> InternalSnapshot {
        var internalSnapshot = InternalSnapshot()
        let sections = snapshot.sectionIdentifiers
        internalSnapshot.appendSections(sections.ids)
        for section in sections {
            let elements = snapshot.itemIdentifiers(inSection: section)
            internalSnapshot.appendItems(elements.ids, toSection: section.id)
        }
        return internalSnapshot
    }
    
    internal func updateSectionHeaderRows() {
        sectionRowIndexes.removeAll()
        guard sectionHeaderViewProvider != nil else { return }
        var row = 0
        for section in sections {
            sectionRowIndexes.append(row)
            row = row + 1 + currentSnapshot.numberOfItems(inSection: section)
        }
    }
    
    /**
     The default animation the UI uses to show differences between rows.
     
     The default value of this property is `effectFade`.
     
     If you set the value of this property, the new value becomes the default row animation for the next update that uses ``apply(_:_:completion:)``.
     */
    public var defaultRowAnimation: NSTableView.AnimationOptions {
        get { self.dataSource.defaultRowAnimation }
        set { self.dataSource.defaultRowAnimation = newValue }
    }
    
    @objc dynamic internal var _defaultRowAnimation: UInt {
        return self.dataSource.defaultRowAnimation.rawValue
    }
    
    /**
     Creates a diffable data source with the specified cell registration, and connects it to the specified table view.
     
     To connect a diffable data source to a table view, you create the diffable data source using this initializer, passing in the table view you want to associate with that data source. You also pass in a cell registration, where each of your cells gets determine how to display your data in the UI.
     
     ```swift
     dataSource = AdvanceTableViewDiffableDataSource<Section, Element>(tableView: tableView, cellRegistration: cellRegistration)
     ```
     
     - Parameters:
     - tableView: The initialized table view object to connect to the diffable data source.
     - cellRegistration: A rell registration which returns each of the cells for the table view from the data the diffable data source provides.
     */
    public convenience init<I: NSTableCellView>(tableView: NSTableView, cellRegistration: NSTableView.CellRegistration<I, Item>) {
        self.init(tableView: tableView, cellProvider:  {
            _tableView, column, row, element in
            return _tableView.makeCell(using: cellRegistration, forColumn: column, row: row, element: element)!
        })
    }
    
    /**
     Creates a diffable data source with the specified cell registrations, and connects it to the specified table view.
     
     To connect a diffable data source to a table view, you create the diffable data source using this initializer, passing in the table view you want to associate with that data source. You also pass in a cell registration, where each of your cells gets determine how to display your data in the UI.
     
     ```swift
     dataSource = AdvanceTableViewDiffableDataSource<Section, Element>(tableView: tableView, cellRegistrations: cellRegistrations)
     ```
     
     - Parameters:
     - tableView: The initialized table view object to connect to the diffable data source.
     - cellRegistrations: Cell registratiosn which returns each of the cells for the table view from the data the diffable data source provides.
     */
    public convenience init(tableView: NSTableView, cellRegistrations: [NSTableViewCellRegistration]) {
        self.init(tableView: tableView, cellProvider:  {
            _tableView, column, row, element in
            let cellRegistration = cellRegistrations.first(where: {$0.columnIdentifier == column.identifier})!
            return (cellRegistration as! _NSTableViewCellRegistration).makeView(tableView, column, row, element)!
        })
    }
    
    /**
     Creates a diffable data source with the specified cell provider, and connects it to the specified table view.
     
     To connect a diffable data source to a table view, you create the diffable data source using this initializer, passing in the table view you want to associate with that data source. You also pass in a item provider, where you configure each of your cells to determine how to display your data in the UI.
     
     ```swift
     dataSource = AdvanceTableViewDiffableDataSource<Section, Element>(tableView: tableView, itemProvider: {
     (tableView, tableColumn, row, element) in
     // configure and return cell
     })
     ```
     
     - Parameters:
     - tableView: The initialized table view object to connect to the diffable data source.
     - cellProvider: A closure that creates and returns each of the cells for the table view from the data the diffable data source provides.
     */
    public init(tableView: NSTableView, cellProvider: @escaping CellProvider) {
        self.tableView = tableView
        super.init()
        
        self.dataSource = DataSoure(tableView: self.tableView, cellProvider: {
            [weak self] tableview, tablecolumn, row, itemID in
            guard let self = self, let item = self.items[id: itemID] else { return NSTableCellView() }
            return cellProvider(tableview, tablecolumn, row, item)
        })
        
        self.tableView.registerForDraggedTypes([.itemID])
        self.tableView.setDraggingSourceOperationMask(.move, forLocal: true)
        self.tableView.delegate = self
        self.tableView.isQuicklookPreviewable = Item.self is QuicklookPreviewable.Type
        
    }
    
    /// A closure that configures and returns a cell for a table view from its diffable data source.
    public typealias CellProvider = (_ tableView: NSTableView, _ tableColumn: NSTableColumn, _ row: Int, _ identifier: Item) -> NSView
    
    public func numberOfRows(in tableView: NSTableView) -> Int {
        return dataSource.numberOfRows(in: tableView)
    }
    
    public func tableViewSelectionDidChange(_ notification: Notification) {
        guard selectionHandlers.didSelect != nil || selectionHandlers.didDeselect != nil else {
            previousSelectedIDs = selectedItems.ids
            return
        }
        let selectedIDs = selectedItems.ids
        let deselected = previousSelectedIDs.filter({ selectedIDs.contains($0) == false })
        let selected = selectedIDs.filter({ previousSelectedIDs.contains($0) == false })
        
        if selected.isEmpty == false, let didSelect = selectionHandlers.didSelect {
            let selectedItems = self.items[ids: selected]
            didSelect(selectedItems)
        }
        
        if deselected.isEmpty == false, let didDeselect = selectionHandlers.didDeselect {
            let deselectedItems = self.items[ids: deselected]
            if deselectedItems.isEmpty == false {
                didDeselect(deselectedItems)
            }
        }
        previousSelectedIDs = selectedIDs
    }
    
    public func tableView(_ tableView: NSTableView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet {
        var proposedSelectionIndexes = proposedSelectionIndexes
        sectionRowIndexes.forEach({ proposedSelectionIndexes.remove($0) })
        guard self.selectionHandlers.shouldSelect != nil || self.selectionHandlers.shouldDeselect != nil  else {
            return proposedSelectionIndexes
        }
        let selectedRows = Array(self.tableView.selectedRowIndexes)
        let proposedRows = Array(proposedSelectionIndexes)
        
        let deselected = selectedRows.filter({ proposedRows.contains($0) == false })
        let selected = proposedRows.filter({ selectedRows.contains($0) == false })
        
        var selections: [Item] = []
        let selectedItems = selected.compactMap({item(forRow: $0)})
        let deselectedItems = deselected.compactMap({item(forRow: $0)})
        if selectedItems.isEmpty == false, let shouldSelect = selectionHandlers.shouldSelect {
            selections.append(contentsOf: shouldSelect(selectedItems))
        } else {
            selections.append(contentsOf: selectedItems)
        }
        
        if deselectedItems.isEmpty == false, let shouldDeselect = selectionHandlers.shouldDeselect {
            selections.append(contentsOf: shouldDeselect(deselectedItems))
        } else {
            selections.append(contentsOf: deselectedItems)
        }
        
        return IndexSet(selections.compactMap({row(for: $0)}))
    }
    
    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        return self.dataSource.tableView(tableView, viewFor: tableColumn, row: row)
    }
    
    public func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
        return self.dataSource.tableView(tableView, isGroupRow: row)
    }
    
    public func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return self.dataSource.tableView(tableView, rowViewForRow: row)
    }
    
    public func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        if self.dragingRowIndexes.isEmpty == false {
            let dragingItems = self.dragingRowIndexes.compactMap({item(forRow: $0)})
            guard self.reorderingHandlers.canReorder?(dragingItems) ?? self.allowsReordering else {
                return false
            }
            if let transaction = self.transactionForMovingItems(at: dragingRowIndexes, to: row) {
                let selectedItems = self.selectedItems
                self.reorderingHandlers.willReorder?(transaction)
                self.apply(transaction.finalSnapshot, .withoutAnimation)
                self.selectItems(selectedItems)
                self.reorderingHandlers.didReorder?(transaction)
            }
        }
        return true
    }
    
    public func tableView( _ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        if dropOperation == .above {
            return .move
        }
        return []
    }
    
    public func tableView( _ tableView: NSTableView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forRowIndexes rowIndexes: IndexSet) {
        self.dragingRowIndexes = rowIndexes
    }
    
    public func tableView(_ tableView: NSTableView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        self.dragingRowIndexes.removeAll()
    }
    
    public func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        if let element = self.item(forRow: row) {
            let item = NSPasteboardItem()
            item.setString(String(element.id.hashValue), forType: .itemID)
            return item
        }
        return nil
    }
    
    public func tableView(_ tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableView.RowActionEdge) -> [NSTableViewRowAction] {
        if let item = item(forRow: row), let rowActionProvider = self.rowActionProvider {
            return rowActionProvider(item, edge)
        }
        return []
    }
    
    public func tableViewColumnDidMove(_ notification: Notification) {
        guard let oldPos = notification.userInfo?["NSOldColumn"] as? Int,
              let newPos = notification.userInfo?["NSNewColumn"] as? Int,
              let tableColumn = self.tableView.tableColumns[safe: newPos] else { return }
        self.columnHandlers.didReorder?(tableColumn, oldPos, newPos)
    }
    
    public func tableViewColumnDidResize(_ notification: Notification) {
        guard let tableColumn = notification.userInfo?["NSTableColumn"] as? NSTableColumn, let oldWidth = notification.userInfo?["NSOldWidth"] as? CGFloat else { return }
        self.columnHandlers.didResize?(tableColumn, oldWidth)
    }
    
    public func tableView(_ tableView: NSTableView, shouldReorderColumn columnIndex: Int, toColumn newColumnIndex: Int) -> Bool {
        guard let tableColumn = self.tableView.tableColumns[safe: columnIndex] else { return true }
        return self.columnHandlers.shouldReorder?(tableColumn, newColumnIndex) ?? true
    }
    
    internal func setupRightDownMonitor() {
        if menuProvider != nil, rightDownMonitor == nil {
            self.rightDownMonitor = NSEvent.localMonitor(for: [.rightMouseDown]) { event in
                self.tableView.menu = nil
                if let contentView = self.tableView.window?.contentView {
                    let location = event.location(in: contentView)
                    if let view = contentView.hitTest(location), view.isDescendant(of: self.tableView) {
                        let location = event.location(in: self.tableView)
                        if self.tableView.bounds.contains(location) {
                            self.setupMenu(for: location)
                        }
                    }
                }
                return event
            }
        } else if menuProvider == nil, rightDownMonitor != nil {
            rightDownMonitor = nil
        }
    }
    
    internal func setupMenu(for location: CGPoint) {
        if let menuProvider = self.menuProvider {
            if let item = self.item(at: location) {
                var menuItems: [Item] = [item]
                let selectedItems = self.selectedItems
                if selectedItems.contains(item) {
                    menuItems = selectedItems
                }
                self.tableView.menu = menuProvider(menuItems)
            } else {
                self.tableView.menu = menuProvider([])
            }
        }
    }
    
    internal func setupHoverObserving() {
        if self.hoverHandlers.isHovering != nil || self.hoverHandlers.didEndHovering != nil {
            self.tableView.setupObservingView()
            if hoveredRowObserver == nil {
                hoveredRowObserver = self.tableView.observeChanges(for: \.hoveredRow, handler: { old, new in
                    guard old != new else { return }
                    if let didEndHovering = self.hoverHandlers.didEndHovering,  let oldRow = old?.item {
                        if oldRow != -1, let item = self.item(forRow: oldRow) {
                            didEndHovering(item)
                        }
                    }
                    if let isHovering = self.hoverHandlers.isHovering,  let newRow = new?.item {
                        if newRow != -1, let item = self.item(forRow: newRow) {
                            isHovering(item)
                        }
                    }
                })
            }
        } else {
            hoveredRowObserver = nil
        }
    }
}

extension AdvanceTableViewDiffableDataSource: NSTableViewQuicklookProvider {
    public func tableView(_ tableView: NSTableView, quicklookPreviewForRow row: Int) -> QuicklookPreviewable? {
        if let item = self.item(forRow: row), let rowView = self.rowView(for: item) {
            if let previewable = item as? QuicklookPreviewable {
                return QuicklookPreviewItem(previewable, view: rowView)
            } else if let previewable = rowView.cellViews.compactMap({$0.quicklookPreview}).first {
                return QuicklookPreviewItem(previewable, view: rowView)
            }
        }
        return nil
    }
}