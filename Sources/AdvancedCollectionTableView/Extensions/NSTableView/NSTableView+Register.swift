//
//  NSTableView+Nibless.swift
//
//
//  Created by Florian Zand on 10.12.22.
//

import AppKit
import FZSwiftUtils
import FZUIKit

extension NSTableView {
    /**
     Registers a class to use when creating new cells in the table view.

     Use this method to register the classes that represent cells in your table view. When you request an cell using the ``makeView(for:)`` method, the table view recycles an existing cell with the same class or creates a new one by instantiating your class.

     - Parameter cellClass: The table cell view class to register.
     */
    public func register(_ cellClass: NSTableCellView.Type) {
        register(cellClass, forIdentifier: .init(cellClass))
    }

    func register(_ cellClass: NSTableCellView.Type, forIdentifier identifier: NSUserInterfaceItemIdentifier) {
        Self.swizzleTableViewCellRegister()
        registeredCellsByIdentifier[identifier] = cellClass
        registeredCellsByIdentifier = registeredCellsByIdentifier
    }

    /**
     Returns a new or existing view with the specified table cell class.

     The be able to create a table view cell from a cell class, you have to register it first via ``register(_:)``.

     When this method is called, the table view automatically instantiates the cell view with the specified owner, which is usually the table view’s delegate. (The owner is useful in setting up outlets and target/actions from the view.).

     This method may also return a reused cell view with the same class that is no longer available on screen. If the cell class isn't registered, the cell can’t be instantiated or can't found in the reuse queue, this method returns nil.

     This method is usually called by the delegate in `tableView(_:viewFor:row:)`, but it can also be overridden to provide custom views for cell class. Note that `awakeFromNib()` is called each time this method is called, which means that `awakeFromNib` is also called on owner, even though the owner is already awake.

     - Parameter cellClass: The class of the table cell view.

     - Returns:The table cell view, or `nil` if the cell class isn't registered or the cell couldn't be created.
     */
    public func makeView<TableCellView: NSTableCellView>(for cellClass: TableCellView.Type) -> TableCellView? {
        return makeView(for: cellClass, withIdentifier: .init(cellClass))
    }

    func makeView<TableCellView: NSTableCellView>(for _: TableCellView.Type, withIdentifier identifier: NSUserInterfaceItemIdentifier) -> TableCellView? {
        if isReconfiguratingRows, let reconfigureIndexPath = reconfigureIndexPath, let cell = view(atColumn: reconfigureIndexPath.section, row: reconfigureIndexPath.item, makeIfNecessary: false) as? TableCellView {
            return cell
        }
        return makeView(withIdentifier: identifier, owner: nil) as? TableCellView
    }

    /**
     The dictionary of all registered cells for view-based table view identifiers.

     Each key in the dictionary is the identifier string (given by `NSUserInterfaceItemIdentifier`) used to register the cell view in the ``register(_:forIdentifier:)`` method. The value of each key is the corresponding `NSTableCellView` class.
     */
    var registeredCellsByIdentifier: [NSUserInterfaceItemIdentifier: NSTableCellView.Type] {
        get { getAssociatedValue(key: "registeredCellsByIdentifier", object: self, initialValue: [:]) }
        set { set(associatedValue: newValue, key: "registeredCellsByIdentifier", object: self) }
    }

    @objc func swizzled_register(_ nib: NSNib?, forIdentifier identifier: NSUserInterfaceItemIdentifier) {
        if nib == nil, registeredCellsByIdentifier[identifier] != nil {
            registeredCellsByIdentifier[identifier] = nil
        }
        swizzled_register(nib, forIdentifier: identifier)
    }

    @objc func swizzled_makeView(withIdentifier identifier: NSUserInterfaceItemIdentifier, owner: Any?) -> NSView? {
        if let registeredCellClass = registeredCellsByIdentifier[identifier] {
            if let tableCellView = swizzled_makeView(withIdentifier: identifier, owner: owner) {
                return tableCellView
            } else {
                let tableCellView = registeredCellClass.init(frame: .zero)
                tableCellView.identifier = identifier
                return tableCellView
            }
        }
        return swizzled_makeView(withIdentifier: identifier, owner: owner)
    }

    static var didSwizzleTableViewCellRegister: Bool {
        get { getAssociatedValue(key: "didSwizzleTableViewCellRegister", object: self, initialValue: false) }
        set { set(associatedValue: newValue, key: "didSwizzleTableViewCellRegister", object: self) }
    }

    @objc static func swizzleTableViewCellRegister() {
        guard didSwizzleTableViewCellRegister == false else { return }
        do {
            try Swizzle(NSTableView.self) {
                #selector(self.makeView(withIdentifier:owner:)) <-> #selector(self.swizzled_makeView(withIdentifier:owner:))
                #selector((self.register(_:forIdentifier:)) as (NSTableView) -> (NSNib?, NSUserInterfaceItemIdentifier) -> Void) <-> #selector(self.swizzled_register(_:forIdentifier:))
            }
            didSwizzleTableViewCellRegister = true
        } catch {
            Swift.debugPrint(error)
        }
    }
}
