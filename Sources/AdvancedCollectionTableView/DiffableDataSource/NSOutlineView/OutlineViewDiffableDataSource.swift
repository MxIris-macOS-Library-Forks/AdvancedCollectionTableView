//
//  OutlineViewDiffableDataSource.swift
//
//
//  Created by Florian Zand on 09.01.25.
//

import AppKit
import FZQuicklook
import FZUIKit
import FZSwiftUtils

/**
 The object you use to manage data and provide items for a outline view.

 The diffable data source provides:
 - Expanding/collapsing items via ``expanionHandlers-swift.property``.
 - Reordering items via ``reorderingHandlers-swift.property``.
 - Deleting items via  ``deletingHandlers-swift.property``.
 - Quicklook previews of items via spacebar by providing items conforming to `QuicklookPreviewable`.
 - Right click menu provider for selected items via ``menuProvider``.

 __It includes handlers for:__

 - Selecting items via ``selectionHandlers-swift.property``.
 - Hovering items by mouse via ``hoverHandlers-swift.property``.
 - Table column handlers via ``columnHandlers-swift.property``.

 ### Configurating the data source

 To connect a diffable data source to a outline view, you create the diffable data source using its ``init(outlineView:cellProvider:)`` or ``init(outlineView:cellRegistration:)`` initializer, passing in the outline view you want to associate with that data source.

 ```swift
 outlineView.dataSource = OutlineViewDiffableDataSource<Item>(outlineView: outlineView, cellRegistration: cellRegistration)
 ```

 Then, you generate the current state of the data and display the data in the UI by constructing and applying a snapshot. For more information, see `NSDiffableDataSourceSnapshot`.
 
 - Note: Each of your items must have unique identifiers.

 - Note: Don’t change the `dataSource` or `delegate` on the outline view after you configure it with a diffable data source. If the outline view needs a new data source after you configure it initially, create and configure a new outline view and diffable data source.
 */
public class OutlineViewDiffableDataSource<ItemIdentifierType: Hashable>: NSObject, NSOutlineViewDataSource {
    
    weak var outlineView: NSOutlineView!
    var currentSnapshot = OutlineViewDiffableDataSourceSnapshot<ItemIdentifierType>()
    let cellProvider: CellProvider
    var keyDownMonitor: NSEvent.Monitor?
    var hoveredRowObserver: KeyValueObservation?
    var delegate: Delegate!
    var draggedItems: [ItemIdentifierType] = []
    var draggedParent: ItemIdentifierType?
    var draggedIndexes: [Int] = []
    var dropItems: [ItemIdentifierType] = []
    var dropContent: [PasteboardReading] = []
    var isApplyingSnapshot = false
    lazy var groupRowTableColumn = NSTableColumn()
    
    /// The closure that configures and returns the outline view’s row views from the diffable data source.
    open var rowViewProvider: RowViewProvider?
    
    /**
     A closure that configures and returns a row view for a outline view from its diffable data source.
     
     - Parameters:
        - outlineView: The outline view to configure this row view for.
        - row: The row of the row view.
        - item: The item of the row.
     
     - Returns: A configured row view object.
     */
    public typealias RowViewProvider = (_ outlineView: NSOutlineView, _ row: Int, _ item: ItemIdentifierType) -> NSTableRowView
    
    /// Applies the specified row view registration to configure and return the outline view’s rows views.
    open func applyRowViewRegistration<Row: NSTableRowView>(_ registration: NSTableView.RowRegistration<Row, ItemIdentifierType>) {
        rowViewProvider = { tableView, row, item in
            registration.makeView(tableView, row, item)
        }
    }
    
    /// The closure that configures and returns cell views for the outline view’s group items.
    open var groupItemCellProvider: GroupItemCellProvider?
    
    /// Applies the specified cell registration to configures and returns cell views for the outline view’s group items.
    open func applyGroupItemCellRegistration<Cell: NSTableCellView>(_ registration: NSTableView.CellRegistration<Cell, ItemIdentifierType>) {
        groupItemCellProvider = { outlineView, item in
            outlineView.makeCellView(using: registration, forColumn: self.groupRowTableColumn, row: 0, item: item)!
        }
    }
        
    /**
     A closure that configures and returns a cell view for a outline view group row.
     
     - Parameters:
        - outlineView: The outline view to configure this cell for.
        - item: The item for this cell.
     
     - Returns: A configured cell object.
     */
    public typealias GroupItemCellProvider = (_ outlineView: NSOutlineView, _ identifier: ItemIdentifierType) -> NSView

    
    /**
     The right click menu provider.
     
     The provided menu is displayed when the user right-clicks the outline view. If you don't want to display a menu, return `nil`.
     
     `items` provides:
     - if right-click on a **selected item**, all selected items,
     - else if right-click on a **non-selected item**, that item,
     - else an empty array.
     */
    open var menuProvider: ((_ items: [ItemIdentifierType]) -> NSMenu?)? = nil {
        didSet {
            if menuProvider != nil {
                outlineView.menuProvider = { [weak self] location in
                    guard let self = self else { return nil }
                    return self.menuProvider?(self.items(for: location))
                }
            } else {
                outlineView.menuProvider = nil
            }
        }
    }
    
    /**
     The item tint configuration provider.
     
     The provided tint configuration is used to customize an item’s tinting behavior.
     */
    open var tintConfigurationProvider: ((_ item: ItemIdentifierType) -> NSTintConfiguration?)? = nil {
        didSet {
            guard (oldValue == nil && tintConfigurationProvider != nil) || (oldValue != nil && tintConfigurationProvider == nil) else { return }
            outlineView.reloadData()
        }
    }
    
    /**
     The handler that gets called when the user right-clicks the outline view.
     
     `items` provides:
     - if right-click on a **selected item**, all selected items,
     - else if right-click on a **non-selected item**, that item,
     - else an empty array.
     */
    open var rightClickHandler: ((_ items: [ItemIdentifierType]) -> ())? = nil {
        didSet {
            if rightClickHandler != nil {
                outlineView.mouseHandlers.rightDown = { [weak self] event in
                    guard let self = self, let handler = self.rightClickHandler else { return }
                    handler(self.outlineView.rightClickRowIndexes(for: event).compactMap({ self.item(forRow: $0) }))
                }
            } else {
                outlineView.mouseHandlers.rightDown = nil
            }
        }
    }
    
    /// The handlers for selecting items.
    open var selectionHandlers = SelectionHandlers()
    
    /// The handlers for expanding/collapsing items.
    open var expanionHandlers = ExpanionHandlers()
    
    /**
     The handlers for deleting items.
     
     Provide ``DeletingHandlers-swift.struct/canDelete`` to support the deleting of items in your outline view.
     
     The system calls the ``DeletingHandlers-swift.struct/didDelete`` handler after a deleting transaction (``DiffableDataSourceTransaction``) occurs, so you can update your data backing store with information about the changes.
     
     ```swift
     // Allow every item to be deleted
     dataSource.deletingHandlers.canDelete = { items in return items }
     
     // Option 1: Update the backing store from a CollectionDifference
     dataSource.deletingHandlers.didDelete = { [weak self] items, transaction in
     guard let self = self else { return }
     
     if let updatedBackingStore = self.backingStore.applying(transaction.difference) {
     self.backingStore = updatedBackingStore
     }
     }
     
     // Option 2: Update the backing store from the final items
     dataSource.deletingHandlers.didDelete = { [weak self] items, transaction in
     guard let self = self else { return }
     
     self.backingStore = transaction.finalSnapshot.itemIdentifiers
     }
     ```
     */
    open var deletingHandlers = DeletingHandlers() {
        didSet { setupKeyDownMonitor() }
    }
    
    /// The handlers for dropping items inside the outline view.
    open var droppingHandlers = DroppingHandlers()
    
    /**
     The handlers for reordering items.
     
     Provide ``ReorderingHandlers-swift.struct/canReorder`` to support the reordering of items in your table view.
     
     The system calls the ``ReorderingHandlers-swift.struct/didReorder`` handler after a reordering transaction (``DiffableDataSourceTransaction``) occurs, so you can update your data backing store with information about the changes.
     
     ```swift
     // Allow every item to be reordered
     dataSource.reorderingHandlers.canReorder = { items in return true }

     // Option 1: Update the backing store from a CollectionDifference
     dataSource.reorderingHandlers.didDelete = { [weak self] items, transaction in
         guard let self = self else { return }
         
         if let updatedBackingStore = self.backingStore.applying(transaction.difference) {
             self.backingStore = updatedBackingStore
         }
     }
     
     // Option 1: Update the backing store from a CollectionDifference
     dataSource.reorderingHandlers.didDelete = { [weak self] items, transaction in
         guard let self = self else { return }
         
         if let updatedBackingStore = self.backingStore.applying(transaction.difference) {
             self.backingStore = updatedBackingStore
         }
     }
     
     // Option 2: Update the backing store from the final items
     dataSource.reorderingHandlers.didReorder = { [weak self] items, transaction in
         guard let self = self else { return }
         
         self.backingStore = transaction.finalSnapshot.itemIdentifiers
     }
     ```
     */
    open var reorderingHandlers = ReorderingHandlers()

        
    /// The handlers for hovering items with the mouse.
    open var hoverHandlers = HoverHandlers() {
        didSet {
            //  setupHoverObserving()
        }
    }
    
    /// The handlers for outline columns.
    open var columnHandlers = ColumnHandlers()
    
    /**
     The view that is displayed when the datasource doesn't contain any items.
     
     When using this property, ``emptyContentConfiguration`` is set to `nil`.
     */
    open var emptyView: NSView? {
        get { emptyContentView?.view }
        set {
            if let newValue = newValue {
                if let emptyContentView = emptyContentView {
                    emptyContentView.view = newValue
                } else {
                    emptyContentView = EmptyView(view: newValue)
                }
                updateEmptyView()
            } else {
                emptyContentView?.removeFromSuperview()
                emptyContentView = nil
            }
        }
    }
    
    /**
     The content configuration that content view is displayed when the datasource doesn't contain any items.
     
     When using this property, ``emptyView`` is set to `nil`.
     */
    open var emptyContentConfiguration: NSContentConfiguration? {
        get { emptyContentView?.configuration }
        set {
            if let configuration = newValue {
                if let emptyContentView = emptyContentView {
                    emptyContentView.configuration = configuration
                } else {
                    emptyContentView = EmptyView(configuration: configuration)
                }
                updateEmptyView()
            } else {
                emptyContentView?.removeFromSuperview()
                emptyContentView = nil
            }
        }
    }
    
    var emptyContentView: EmptyView?
    
    /**
     The handler that gets called when the data source switches between an empty and non-empty snapshot or viceversa.
     
     You can use this handler e.g. if you want to update your empty content configuration or view.
     
     - Parameter isEmpty: A Boolean value indicating whether the current snapshot is empty.
     */
    open var emptyHandler: ((_ isEmpty: Bool)->())? {
        didSet {
            emptyHandler?(currentSnapshot.items.isEmpty)
        }
    }
    
    func updateEmptyView(previousIsEmpty: Bool? = nil) {
        if !currentSnapshot.items.isEmpty {
            emptyView?.removeFromSuperview()
            emptyContentView?.removeFromSuperview()
        } else if let emptyContentView = emptyContentView, emptyContentView.superview != outlineView {
            outlineView.addSubview(withConstraint: emptyContentView)
        }
        if let emptyHandler = self.emptyHandler, let previousIsEmpty = previousIsEmpty {
            if previousIsEmpty != currentSnapshot.items.isEmpty {
                emptyHandler(currentSnapshot.items.isEmpty)
            }
        }
    }
    
    
    /**
     The default animation the UI uses to show differences between rows.
     
     The default value of this property is `effectFade`.
     
     If you set the value of this property, the new value becomes the default row animation for the next update that uses ``apply(_:_:completion:)``.
     */
    public var defaultRowAnimation: NSTableView.AnimationOptions = .effectFade
    
    @objc dynamic var _defaultRowAnimation: UInt {
        defaultRowAnimation.rawValue
    }
    
    /// All current items in the outline view.
    open var items: [ItemIdentifierType] { currentSnapshot.items }
    
    /// The selected items.
    open var selectedItems: [ItemIdentifierType] {
        get { outlineView.selectedItems as! [ItemIdentifierType] }
        set {
            guard newValue != selectedItems else { return }
            selectItems(newValue)
        }
    }
    
    /// Returns the item at the specified row in the outline view.
    open func item(forRow row: Int) -> ItemIdentifierType? {
        outlineView.item(atRow: row) as? ItemIdentifierType
    }
    
    /// Returns the row for the specified item.
    open func row(for item: ItemIdentifierType) -> Int? {
        outlineView.row(forItem: item)
    }
    
    /**
     Returns the item of the specified point in the outline view.
     
     - Parameter point: The point in in the outline view.
     - Returns: The item at the point or `nil` if there isn't any item.
     */
    open func item(at point: CGPoint) -> ItemIdentifierType? {
        let row = outlineView.row(at: point)
        if row != -1 {
            return item(forRow: row)
        }
        return nil
    }
    
    func items(for location: CGPoint) -> [ItemIdentifierType] {
        if let item = item(at: location) {
            var items: [ItemIdentifierType] = [item]
            let selectedItems = selectedItems
            if selectedItems.contains(item) {
                items = selectedItems
            }
            return items
        }
        return []
    }
    
    /// Selects all specified items.
    open func selectItems(_ items: [ItemIdentifierType], byExtendingSelection: Bool = false) {
        let rows = IndexSet(items.compactMap{row(for: $0)})
        outlineView.selectRowIndexes(rows, byExtendingSelection: byExtendingSelection)
    }
    
    /// Deselects all specified items.
    open func deselectItems(_ items: [ItemIdentifierType]) {
        items.compactMap{row(for: $0)}.forEach { outlineView.deselectRow($0) }
    }
    
    /// Scrolls the outline view to the specified item.
    open func scrollToItem(_ item: ItemIdentifierType) {
        if let row = row(for: item) {
            outlineView.scrollRowToVisible(row)
        }
    }
    
    /// Reloads the outline view cells for the specified items.
    open func reloadItems(_ items: [ItemIdentifierType], reloadChildren: Bool = false, animated: Bool = false) {
        if animated {
            NSView.animate {
                items.forEach({ self.outlineView.animator().reloadItem($0, reloadChildren: reloadChildren) })
            }
        } else {
            items.forEach({ outlineView.reloadItem($0, reloadChildren: reloadChildren) })
        }
    }
    
    /// Updates the data for the specified items, preserving the existing outline view cells for the items.
    open func reconfigureItems(_ items: [ItemIdentifierType]) {
        let rows = IndexSet(items.compactMap { row(for: $0) })
        outlineView.reconfigureRows(at: rows)
    }
    
    /// The items that are visible.
    open var visibleItems: [ItemIdentifierType] {
        outlineView.visibleRowIndexes().compactMap { item(forRow: $0) }
    }
    
    /**
     Expands a specified item and, optionally, its children.
     
     - Parameters:
        - item: The items to expand.
        - expandChildren: If `true`, recursively expands item and its children. If `false`, expands item only.
     */
    open func expand(_ item: ItemIdentifierType,  expandChildren: Bool = false) {
        expand([item], expandChildren: expandChildren)
    }
    
    /**
     Expands the specified items and, optionally, their children.
     
     - Parameters:
        - items: The items to expand.
        - expandChildren: If `true`, recursively expands item and its children. If `false`, expands item only.
     */
    open func expand(_ items: [ItemIdentifierType],  expandChildren: Bool = false) {
        items.forEach({ outlineView.expandItem($0, expandChildren: expandChildren) })
    }
    
    /**
     Collapses a given item and, optionally, its children.
     
     - Parameters:
        - item: The item to expand.
        - collapseChildren: If `true`, recursively collapses item and its children. If `false`, collapses item only.
     */
    open func collapse(_ item: ItemIdentifierType,  collapseChildren: Bool = false) {
        collapse([item], collapseChildren: collapseChildren)
    }
    
    /**
     Collapses the specified items and, optionally, their children.
     
     - Parameters:
        - items: The items to expand.
        - collapseChildren: If `true`, recursively collapses item and its children. If `false`, collapses item only.
     */
    open func collapse(_ items: [ItemIdentifierType],  collapseChildren: Bool = false) {
        items.forEach({ outlineView.collapseItem($0, collapseChildren: collapseChildren) })
    }
    
    func rowView(for item: ItemIdentifierType) -> NSTableRowView? {
        if let row = row(for: item) {
            return outlineView.rowView(atRow: row, makeIfNecessary: false)
        }
        return nil
    }
    
    
    /**
     Creates a diffable data source with the specified cell provider, and connects it to the specified outline view.
     
     To connect a diffable data source to a outline view, you create the diffable data source using this initializer, passing in the outline view you want to associate with that data source. You also pass in a item provider, where you configure each of your cells to determine how to display your data in the UI.
     
     ```swift
     dataSource = OutlineViewDiffableDataSource<Item>(outlineView: outlineView, cellProvider: {
     (outlineView, tableColumn, item) in
     // configure and return cell
     })
     ```
     
     - Parameters:
        - outlineView: The initialized outline view object to connect to the diffable data source.
        - cellProvider: A closure that creates and returns each of the cells for the outline view from the data the diffable data source provides.
     */
    public init(outlineView: NSOutlineView, cellProvider: @escaping CellProvider) {
        self.outlineView = outlineView
        self.cellProvider = cellProvider
        super.init()
        self.delegate = .init(self)
        outlineView.dataSource = self
        outlineView.delegate = delegate
        outlineView.registerForDraggedTypes([.itemID, .fileURL, .tiff, .png, .string])
        outlineView.isQuicklookPreviewable = ItemIdentifierType.self is QuicklookPreviewable.Type
        
    }
    
    /**
     A closure that configures and returns a cell view for a outline view from its diffable data source.
     
     - Parameters:
        - outlineView: The outline view to configure this cell for.
        - tableColumn: The table column of the cell.
        - item: The item for this cell.
     
     - Returns: A configured cell object.
     */
    public typealias CellProvider = (_ outlineView: NSOutlineView, _ tableColumn: NSTableColumn, _ identifier: ItemIdentifierType) -> NSView
    
    /**
     Creates a diffable data source with the specified cell registration, and connects it to the specified outline view.
     
     To connect a diffable data source to a outline view, you create the diffable data source using this initializer, passing in the outline view you want to associate with that data source. You also pass in a cell registration, where each of your cells gets determine how to display your data in the UI.
     
     ```swift
     dataSource = OutlineViewDiffableDataSource<Item>(outlineView: outlineView, cellRegistration: cellRegistration)
     ```
     
     - Parameters:
        - outlineView: The initialized outline view object to connect to the diffable data source.
        - cellRegistration: A cell registration which returns each of the cells for the outline view from the data the diffable data source provides.
     */
    public convenience init<Cell: NSTableCellView>(outlineView: NSOutlineView, cellRegistration: NSTableView.CellRegistration<Cell, ItemIdentifierType>) {
        self.init(outlineView: outlineView, cellProvider: {
            outlineView, column, item in
            outlineView.makeCellView(using: cellRegistration, forColumn: column, row: 0, item: item)!
        })
    }
    
    /**
     Creates a diffable data source with the specified cell registrations, and connects it to the specified outline view.
          
     Specify column identifiers for each of the cell registrations using: ``AppKit/NSTableView/CellRegistration/init(columnIdentifiers:handler:)``
     
     The column identifiers are used to create the cells for each column with the coresponding column identifier.
     
     ```swift
     dataSource = OutlineViewDiffableDataSource<Item>(outlineView: outlineView, cellRegistrations: cellRegistrations)
     ```
     
     - Parameters:
        - outlineView: The initialized outline view object to connect to the diffable data source.
        - cellRegistrations: Cell registrations which returns each of the cells for the outline view from the data the diffable data source provides.
     */
    public convenience init(outlineView: NSOutlineView, cellRegistrations: [NSTableViewCellRegistration]) {
        self.init(outlineView: outlineView, cellProvider: {
            outlineView, column, item in
            if let cellRegistration = (cellRegistrations.first(where: { $0.columnIdentifiers.contains(column.identifier) }) ?? cellRegistrations.first(where: { $0.columnIdentifiers.isEmpty })) as? _NSTableViewCellRegistration {
                return cellRegistration.makeView(outlineView, column, 0, item) ?? NSTableCellView()
            }
            return NSTableCellView()
        })
    }
    
    /// Returns a representation of the current state of the data in the outline view.
    public func snapshot() -> OutlineViewDiffableDataSourceSnapshot<ItemIdentifierType> {
        currentSnapshot
    }
    
    /// Returns a representation of the current state of the data in the specified item of the collection view.
    public func snapshot(for item: ItemIdentifierType) -> OutlineViewDiffableDataSourceSnapshot<ItemIdentifierType> {
        guard currentSnapshot.nodes[item] != nil else { return emptySnapshot() }
        let current = snapshot()
        var snapshot = emptySnapshot()
        snapshot.nodes[item] = .init()
        current.descendants(of: item).forEach({ snapshot.nodes[$0] = current.nodes[$0] })
        current.children(of: item).forEach({ snapshot.nodes[$0]?.parent = item })
        snapshot.updateOrderedItems()
        return snapshot
    }
    
    /// Returns an empty snapshot.
    public func emptySnapshot() -> OutlineViewDiffableDataSourceSnapshot<ItemIdentifierType> {
        .init()
    }
    
    /**
     Updates the UI to reflect the state of the data in the snapshot, optionally animating the UI changes.
     
     The system interrupts any ongoing item animations and immediately reloads the outline view’s content.
     
     - Parameters:
        - snapshot: The snapshot that reflects the new state of the data in the outline view.
        - option: Option how to apply the snapshot to the outline view. The default value is `animated`.
        - completion: An optional completion handler which gets called after applying the snapshot. The system calls this closure from the main queue.
     */
    public func apply(_ snapshot: OutlineViewDiffableDataSourceSnapshot<ItemIdentifierType>, _ option: NSDiffableDataSourceSnapshotApplyOption = .animated, completion: (() -> Void)? = nil) {
        isApplyingSnapshot = true
        let current = currentSnapshot
        let previousIsEmpty = currentSnapshot.items.isEmpty
        currentSnapshot = snapshot
        outlineView.apply(snapshot, currentSnapshot: current, option: option, animation: defaultRowAnimation, completion: completion)
         updateEmptyView(previousIsEmpty: previousIsEmpty)
        updateEmptyView(previousIsEmpty: previousIsEmpty)
        isApplyingSnapshot = false
    }
    
    public func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let item = item as? ItemIdentifierType {
            return currentSnapshot.children(of: item)[index]
        }
        return currentSnapshot.rootItems[index]
    }
    
    public func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let item = item {
            return currentSnapshot.children(of: item as! ItemIdentifierType).count
        }
        return currentSnapshot.rootItems.count
    }
    
    public func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        !currentSnapshot.children(of: item as! ItemIdentifierType).isEmpty
    }
    
    public func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forItems draggedItems: [Any]) {
        self.draggedItems = draggedItems.compactMap({$0 as? ItemIdentifierType})
        
        let parents = self.draggedItems.compactMap({ currentSnapshot.parent(of:$0) }).uniqued()
        var children: [ItemIdentifierType] = []
        if parents.isEmpty {
            children = currentSnapshot.rootItems
        } else if parents.count == 1 {
            children = currentSnapshot.children(of: parents[0])
        }
        let indexes = self.draggedItems.compactMap({ children.firstIndex(of: $0 ) })
        if (parents.isEmpty || parents.count == 1), indexes.isIncrementing() {
            self.draggedParent = parents.first
            self.draggedIndexes = indexes.sorted()
        }
    }
    
    public func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        draggedItems = []
        draggedIndexes = []
        draggedParent = nil
        dropItems = []
        dropContent = []
    }
    
    /*
    public var usesGroupItems = false {
        didSet {
            guard oldValue != usesGroupItems else { return }
            reloadItems(currentSnapshot.rootItems)
            updateGroupItems(reload: true)
        }
    }
    
    public var groupItemsAreCollapsable = false {
        didSet {
            guard oldValue != groupItemsAreCollapsable, usesGroupItems else { return }
            updateGroupItems(reload: true)
        }
    }
    
    public enum GroupItemOption {
        case none
        case enabled
        case enabledExpandable
    }
    
    public var groupItems: GroupItemOption = .none
    
    func updateGroupItems(reload: Bool = false) {
        isApplyingSnapshot = true
        if reload {
            reloadItems(currentSnapshot.rootItems)
        }
        if !usesGroupItems {
            let expanded = currentSnapshot.rootItems.filter({ outlineView.isItemExpanded($0) })
            expanded.filter({ currentSnapshot.nodes[$0]?.isExpanded == false }).forEach({ outlineView.collapseItem($0) })
        } else {
            if groupItemsAreCollapsable {
              // Swift.print("CHECKALT", currentSnapshot.rootItems.filter({ outlineView.isItemExpanded($0) }))
                
              //  currentSnapshot.rootItems.filter({ outlineView.isItemExpanded($0) })
               // currentSnapshot.rootItems.compactMap({ currentSnapshot.isExpanded($0) })
                Swift.print("-------")
                Swift.print(currentSnapshot.rootItems.filter({ currentSnapshot.isExpanded($0) }))
                Swift.print(currentSnapshot.rootItems.filter({ !currentSnapshot.isExpanded($0) }))

                currentSnapshot.rootItems.forEach({
                    if currentSnapshot.isExpanded($0) {
                        outlineView.expandItem($0)
                    } else {
                        Swift.print("HERE")
                        outlineView.collapseItem($0)
                    }
                })
                /*
                var collapsing: [ItemIdentifierType] = []
                var expanding: [ItemIdentifierType] = []
                for item in currentSnapshot.rootItems {
                    let isExpanded = outlineView.isItemExpanded(item)
                    let isExpanded1 = currentSnapshot.nodes[item]?.isExpanded ?? false
                    Swift.print("HERE", isExpanded, isExpanded1)

                    if isExpanded != isExpanded1 {
                        if isExpanded {
                            collapsing.append(item)
                        } else {
                            expanding.append(item)
                        }
                    }
                }
                collapsing.forEach({outlineView.collapseItem($0)})
                expanding.forEach({outlineView.expandItem($0)})
/*
                
                var expanded = currentSnapshot.rootItems.filter({ outlineView.isItemExpanded($0) })
                expanded = expanded.filter({ !currentSnapshot.isExpanded($0) })
                    expanded.forEach({ outlineView.collapseItem($0) })
                var collapsed = currentSnapshot.rootItems.filter({ !outlineView.isItemExpanded($0) })
              //  collapsed = collapsed.filter({ currentSnapshot.isExpanded($0) })
                    collapsed.forEach({ outlineView.expandItem($0) })
                Swift.print(expanded)
                Swift.print(currentSnapshot.rootItems.filter({ currentSnapshot.isExpanded($0) }))
                Swift.print("---------")
                Swift.print(collapsed)
                Swift.print(currentSnapshot.rootItems.filter({ !currentSnapshot.isExpanded($0) }))
 */*/
            } else {
                let collapsed = currentSnapshot.rootItems.filter({ !outlineView.isItemExpanded($0) })
                collapsed.forEach({ outlineView.expandItem($0) })
                Swift.print("CHECK", currentSnapshot.rootItems.filter({ outlineView.isItemExpanded($0) }))
            }
        }
        isApplyingSnapshot = false
    }
    */
    
    var previewIndex: Int? = nil
    var previewParent: ItemIdentifierType? = nil
    var previewItems: [ItemIdentifierType] = []
    
    public func outlineView(_ outlineView: NSOutlineView, validateDrop info: any NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        if info.draggingSource as? NSOutlineView === outlineView {
            if let item = item as? ItemIdentifierType, draggedItems.contains(item) {
                return []
            }
            if draggedParent == item as? ItemIdentifierType, let last = draggedIndexes.last, (draggedIndexes + [last+1]).contains(index) {
                return []
            }
            if index == -1, let item = item, delegate.outlineView(outlineView, isGroupItem: item) {
                return []
            }
            if let item = item as? ItemIdentifierType, draggedItems.contains(where: { currentSnapshot.isDescendant(item, of: $0) }) {
                return []
            }
            /*
            if index == -1, !draggedIndexes.isEmpty, (draggedParent == item as? ItemIdentifierType) || (draggedParent == nil && item == nil) {
                return []
            }
            */
            return reorderingHandlers.canReorder?(draggedItems, item as? ItemIdentifierType) ?? true == true ? .move : []
        } else if let canDrop = droppingHandlers.canDrop {
            dropItems = []
            dropContent = info.draggingPasteboard.content
            if canDrop(dropContent, item as? ItemIdentifierType), let items = droppingHandlers.items?(dropContent, item as? ItemIdentifierType), !items.isEmpty {
                dropItems = items
                return .move
            }
        }
        return []
    }
    
    public func outlineView(_ outlineView: NSOutlineView, acceptDrop info: any NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        if let sourceOutlineView = info.draggingSource as? NSOutlineView, sourceOutlineView === outlineView {
            var snapshot = currentSnapshot
            var index = index
            if index == -1 {
                if let item = item as? ItemIdentifierType {
                    index = snapshot.children(of: item).count
                } else {
                    index = snapshot.rootItems.count
                }
            }
            snapshot.move(draggedItems, toIndex: index, of: item as? ItemIdentifierType)
            let transaction = OutlineViewDiffableDataSourceTransaction(initial: currentSnapshot, final: snapshot)
            reorderingHandlers.willReorder?(transaction)
            apply(snapshot, reorderingHandlers.animates ? .animated : .withoutAnimation)
            reorderingHandlers.didReorder?(transaction)
            return true
        } else if !dropItems.isEmpty {
            var snapshot = snapshot()
            snapshot.insert(dropItems, atIndex: index, of: item as? ItemIdentifierType)
            let transaction = OutlineViewDiffableDataSourceTransaction<ItemIdentifierType>.init(initial: currentSnapshot, final: snapshot)
            droppingHandlers.willDrop?(dropContent, item as? ItemIdentifierType, dropItems, transaction)
            apply(snapshot, droppingHandlers.animates ? .animated : .withoutAnimation)
            droppingHandlers.didDrop?(dropContent, item as? ItemIdentifierType, dropItems, transaction)
            return true
        }
        return false
    }
    
    public func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> (any NSPasteboardWriting)? {
        guard let item = item as? ItemIdentifierType else { return nil }
        return NSPasteboardItem(forItem: item)
    }
    
    /// Handlers for selecting items.
    public struct ExpanionHandlers {
        /// The handler that determines if an item should expand. The default value is `nil` which indicates that all items should expand.
        public var shouldExpand: ((ItemIdentifierType) -> Bool)?

        /// The handler that gets called whenever an item expands.
        public var didExpand: ((ItemIdentifierType) -> Void)?

        /// The handler that determines if an item should collapse. The default value is `nil` which indicates that all items should collapse.
        public var shouldCollapse: ((ItemIdentifierType) -> Bool)?

        /// The handler that gets called whenever an item collapses.
        public var didCollapse: ((ItemIdentifierType) -> Void)?
    }
    
    /// Handlers for selecting items.
    public struct SelectionHandlers {
        /// The handler that determines which items should get selected. The default value is `nil` which indicates that all items should get selected.
        public var shouldSelect: (([ItemIdentifierType]) -> [ItemIdentifierType])?

        /// The handler that gets called whenever items get selected.
        public var didSelect: (([ItemIdentifierType]) -> Void)?

        /// The handler that determines which items should get deselected. The default value is `nil` which indicates that all items should get deselected.
        public var shouldDeselect: (([ItemIdentifierType]) -> [ItemIdentifierType])?

        /// The handler that gets called whenever items get deselected.
        public var didDeselect: (([ItemIdentifierType]) -> Void)?
    }
    
    /**
     Handlers for reordering items.
     
     Take a look at ``reorderingHandlers-swift.property`` how to support reordering items.
     */
    public struct ReorderingHandlers {
        /// The handler that determines if items can be reordered. The default value is `nil` which indicates that items can't be reordered.
        public var canReorder: ((_ items: [ItemIdentifierType], _ parent: ItemIdentifierType?) -> Bool)?

        /// The handler that that gets called before reordering items.
        public var willReorder: ((_ transaction: OutlineViewDiffableDataSourceTransaction<ItemIdentifierType>) -> Void)?

        /**
         The handler that that gets called after reordering items.

         The system calls the `didReorder` handler after a reordering transaction (``DiffableDataSourceTransaction``) occurs, so you can update your data backing store with information about the changes.
         
         ```swift
         // Allow every item to be reordered
         dataSource.reorderingHandlers.canDelete = { items in return true }

         // Option 1: Update the backing store from a CollectionDifference
         dataSource.reorderingHandlers.didDelete = { [weak self] items, transaction in
             guard let self = self else { return }
             
             if let updatedBackingStore = self.backingStore.applying(transaction.difference) {
                 self.backingStore = updatedBackingStore
             }
         }

         // Option 2: Update the backing store from the final items
         dataSource.reorderingHandlers.didReorder = { [weak self] items, transaction in
             guard let self = self else { return }
             
             self.backingStore = transaction.finalSnapshot.itemIdentifiers
         }
         ```
         */
        public var didReorder: ((_ transaction: OutlineViewDiffableDataSourceTransaction<ItemIdentifierType>) -> Void)?
        
        /// A Boolean value that indicates whether reordering items is animated.
        public var animates: Bool = false
        
        /// A Boolean value that indicates whether rows reorder immediately while the user drags them.
        var reorderImmediately: Bool = true
    }
    
    public struct DeletingHandlers {
        /// The handler that determines which items can be be deleted. The default value is `nil`, which indicates that all items can be deleted.
        public var canDelete: ((_ items: [ItemIdentifierType]) -> [ItemIdentifierType])?

        /// The handler that that gets called before deleting items.
        public var willDelete: ((_ items: [ItemIdentifierType], _ transaction: OutlineViewDiffableDataSourceTransaction<ItemIdentifierType>) -> Void)?

        /**
         The handler that that gets called after deleting items.
         
         The system calls the `didDelete` handler after a deleting transaction (``DiffableDataSourceTransaction``) occurs, so you can update your data backing store with information about the changes.
         
         ```swift
         // Allow every item to be deleted
         dataSource.deletingHandlers.canDelete = { items in return items }

         // Option 1: Update the backing store from a CollectionDifference
         dataSource.deletingHandlers.didDelete = { [weak self] items, transaction in
             guard let self = self else { return }
             
             if let updatedBackingStore = self.backingStore.applying(transaction.difference) {
                 self.backingStore = updatedBackingStore
             }
         }

         // Option 2: Update the backing store from the final items
         dataSource.deletingHandlers.didReorder = { [weak self] items, transaction in
             guard let self = self else { return }
             
             self.backingStore = transaction.finalSnapshot.itemIdentifiers
         }
         ```
         */
        public var didDelete: ((_ items: [ItemIdentifierType], _ transaction: OutlineViewDiffableDataSourceTransaction<ItemIdentifierType>) -> Void)?
        
        /**
         A Boolean value that indicates whether items can be deleted by dragging them outside the outline view.
         
         - Note: You still need to provide the items that can be deleted using ``canDelete``.
         */
        public var isDeletableByDraggingOutside = false
        
        /// A Boolean value that indicates whether deleting items is animated.
        public var animates: Bool = true
    }
    
    /// Handlers for hovering items with the mouse.
    public struct HoverHandlers {
        /// The handler that gets called whenever the mouse is hovering an item.
        public var isHovering: ((ItemIdentifierType) -> Void)?

        /// The handler that gets called whenever the mouse did end hovering an item.
        public var didEndHovering: ((ItemIdentifierType) -> Void)?

        var shouldSetup: Bool {
            isHovering != nil || didEndHovering != nil
        }
    }
    
    /// Handlers for outline view columns.
    public struct ColumnHandlers {
        /// The handler that gets called whenever the  mouse button was clicked in the specified outline column, but the column was not dragged.
        public var didClick: ((_ column: NSTableColumn) -> Void)?
        
        /// The handler that gets called whenever the mouse button was clicked in the specified outline column’s header.
        public var didClickHeader: ((_ column: NSTableColumn) -> Void)?
        
        /// The handler that gets called whenever a column did resize.
        public var didResize: ((_ column: NSTableColumn, _ oldWidth: CGFloat) -> Void)?

        /// The handler that determines whenever a column can be reordered to a new index.
        public var shouldReorder: ((_ column: NSTableColumn, _ newIndex: Int) -> Bool)?

        /// The handler that gets called whenever a column did reorder.
        public var didReorder: ((_ column: NSTableColumn, _ oldIndex: Int, _ newIndex: Int) -> Void)?
        
        /// The handler that determines whenever the user can change the given column’s visibility.
        public var userCanChangeVisibility: ((_ column: NSTableColumn) -> Bool)?
        
        /// The handler that gets called whenever the user did change the visibility of the given columns.
        public var userDidChangeVisibility: ((_ columns: [NSTableColumn]) -> Void)?
        
        /// The handler that gets called whenever the sort descriptors of the columns changed.
        public var sortDescriptorsChanged: ((_ old: [NSSortDescriptor], _ new: [NSSortDescriptor]) -> Void)?
    }
    
    /// Handlers for dropping items inside the outline view.
    public struct DroppingHandlers {
        /// The handler that determines whether a drop with the pasteboard content is accepted.
        public var canDrop: ((_ content: [PasteboardReading], _ parent: ItemIdentifierType?) -> (Bool))?
        /// The handler that determinates the items to be inserted for the pasteboard content.
        public var items: ((_ content: [PasteboardReading], _ parent: ItemIdentifierType?) -> ([ItemIdentifierType]))?
        /// The handler that gets called before new items are dropped.
        public var willDrop: ((_ content: [PasteboardReading], _ parent: ItemIdentifierType?, _ newItems: [ItemIdentifierType], _ transaction: OutlineViewDiffableDataSourceTransaction<ItemIdentifierType>) -> ())?
        /// The handler that gets called after new items are dropped.
        public var didDrop: ((_ content: [PasteboardReading], _ parent: ItemIdentifierType?, _ newItems: [ItemIdentifierType], _ transaction: OutlineViewDiffableDataSourceTransaction<ItemIdentifierType>) -> ())?
        /// A Boolean value that indicates whether dropping items is animated.
        public var animates: Bool = false
        /// A Boolean value that indicates whether the dropped items are previewed.
        public var previewItems = true
    }
    
    func setupKeyDownMonitor() {
        if let canDelete = deletingHandlers.canDelete {
            keyDownMonitor = NSEvent.localMonitor(for: .keyDown) { [weak self] event in
                guard let self = self, event.charactersIgnoringModifiers == String(UnicodeScalar(NSDeleteCharacter)!), self.outlineView.isFirstResponder else { return event }
                let selected = outlineView.selectedItems as! [ItemIdentifierType]
                let itemsToDelete = canDelete(selected)
                guard !itemsToDelete.isEmpty else { return event }
                
                var snapshot = currentSnapshot
                snapshot.delete(itemsToDelete)
                let transaction = OutlineViewDiffableDataSourceTransaction(initial: currentSnapshot, final: snapshot)
                self.deletingHandlers.willDelete?(itemsToDelete, transaction)
                QuicklookPanel.shared.close()
                self.apply(transaction.finalSnapshot, self.deletingHandlers.animates ? .animated : .withoutAnimation)
                self.deletingHandlers.didDelete?(itemsToDelete, transaction)
                
                if !self.outlineView.allowsEmptySelection, self.outlineView.selectedRowIndexes.isEmpty {
                    /*
                    if let item = transaction.initialSnapshot.nextItemForDeleting(itemsToDelete) ?? self.items.first {
                        self.selectItems([item])
                    }
                     */
                }
                return nil
            }
        } else {
            keyDownMonitor = nil
        }
    }
    
    func setupHoverObserving() {
        if hoverHandlers.shouldSetup {
            guard hoveredRowObserver == nil else { return }
            outlineView.setupObservation()
            hoveredRowObserver = outlineView.observeChanges(for: \.hoveredRow, handler: { [weak self] old, new in
                guard let self = self, old != new else { return }
                if let didEndHovering = self.hoverHandlers.didEndHovering, old != -1, let item = self.item(forRow: old) {
                    didEndHovering(item)
                }
                if let isHovering = self.hoverHandlers.isHovering, new != -1, let item = self.item(forRow: new) {
                    isHovering(item)
                }
            })
        } else {
            hoveredRowObserver = nil
        }
    }
}

// MARK: - Quicklook

extension OutlineViewDiffableDataSource where ItemIdentifierType: QuicklookPreviewable {
    /**
     A Boolean value that indicates whether the user can open a quicklook preview of selected items by pressing space bar.
     
     Any item conforming to `QuicklookPreviewable` can be previewed by providing a preview file url.
     */
    public var isQuicklookPreviewable: Bool {
        get { outlineView.isQuicklookPreviewable }
        set { outlineView.isQuicklookPreviewable = newValue }
    }

    /**
     Opens `QuicklookPanel` that presents quicklook previews of the specified items.

     To quicklook the selected items, use outline view's `quicklookSelectedRows()`.

     - Parameters:
        - items: The items to preview.
        - current: The item that starts the preview. The default value is `nil`.
     */
    public func quicklookItems(_ items: [ItemIdentifierType], current: ItemIdentifierType? = nil) {
        let rows = items.compactMap { row(for: $0) }
        if let current = current, let currentRow = row(for: current) {
            outlineView.quicklookRows(at: rows, current: currentRow)
        } else {
            outlineView.quicklookRows(at: rows)
        }
    }
}

extension OutlineViewDiffableDataSource {
    /**
     Sets the specified item sort comperator to the table column.
     
     - Parameters:
        - comparator: The item sorting comperator, or `nil` to remove any sorting comperators from the table column.
        - tableColumn: The table column.
     */
    public func setSortComparator(_ comparator: SortingComparator<ItemIdentifierType>?, forColumn tableColumn: NSTableColumn, activate: Bool = false) {
        if activate, comparator != nil, let key = tableColumn.sortDescriptorPrototype?.key {
            outlineView.sortDescriptors.removeAll(where: { $0.key == key })
        }
        if let comparator = comparator {
            tableColumn.sortDescriptorPrototype = ItemIdentifierTypeSortDescriptor([comparator])
            if activate {
                outlineView.sortDescriptors = [tableColumn.sortDescriptorPrototype!] + outlineView.sortDescriptors
            }
        } else if tableColumn.sortDescriptorPrototype is ItemIdentifierTypeSortDescriptor {
            tableColumn.sortDescriptorPrototype = nil
        }
    }
    
    /**
     Sets the specified item sort comperators to the table column.
     
     - Parameters:
        - comparators: The item sorting comperators.
        - tableColumn: The table column.
     */
    public func setSortComparators(_ comparators: [SortingComparator<ItemIdentifierType>], forColumn tableColumn: NSTableColumn, activate: Bool = false) {
        if activate, !comparators.isEmpty, let key = tableColumn.sortDescriptorPrototype?.key {
            outlineView.sortDescriptors.removeAll(where: { $0.key == key })
        }
        if comparators.isEmpty {
            setSortComparator(nil, forColumn: tableColumn)
        } else {
            tableColumn.sortDescriptorPrototype = ItemIdentifierTypeSortDescriptor(comparators)
            if activate {
                outlineView.sortDescriptors = [tableColumn.sortDescriptorPrototype!] + outlineView.sortDescriptors
            }
        }
    }
    
    class ItemIdentifierTypeSortDescriptor: NSSortDescriptor {
        
        var comparators: [SortingComparator<ItemIdentifierType>] = []
        
        init(_ comparators: [SortingComparator<ItemIdentifierType>], ascending: Bool = true, key: String? = nil) {
            super.init(key: key ?? UUID().uuidString, ascending: ascending, selector: nil)
            self.comparators = comparators
        }
        
        override var reversedSortDescriptor: Any {
            var comparators = comparators
            comparators.editEach({$0.order.toggle() })
            return ItemIdentifierTypeSortDescriptor(comparators, ascending: !ascending, key: key)
        }
        
        override func copy() -> Any {
            ItemIdentifierTypeSortDescriptor(comparators, ascending: ascending, key: key)
        }
        
        override func isEqual(_ object: Any?) -> Bool {
            guard let object = object as? ItemIdentifierTypeSortDescriptor else { return false }
            return object.key == key && object.ascending == ascending && object.comparators == comparators
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
