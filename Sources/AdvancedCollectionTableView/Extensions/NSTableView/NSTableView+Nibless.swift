//
//  NSTableView+.swift
//  NSTableViewRegister
//
//  Created by Florian Zand on 10.12.22.
//

import AppKit
import FZExtensions
import InterposeKit

// Extension to provide registrations of NSTableCellView's via their classes
public extension NSTableView {
    /**
     Registers a class to use when creating new cells in the table view.
     
     Use this method to register the classes that represent cells in your table view. When you request an cell using the ``makeView(withIdentifier:owner:)`` method, the table view recycles an existing cell with the same identifier or creates a new one by instantiating your class.
     
     Use this method to associate one of the NIB's cell views with identifier so that the table can instantiate this view when requested. This method is used when ``makeView(withIdentifier:owner:)`` is called, and there was no NIB created at design time for the specified identifier. This allows dynamic loading of NIBs that can be associated with the table.
     Because a NIB can contain multiple views, you can associate the same NIB with multiple identifiers. To remove a previously associated NIB for identifier, pass in nil for the nib value.
     
     - Parameters:
        - cellClass: A class to use for creating cell. Specify nil to unregister a previously registered class.
        - identifier: The string that identifies the type of cell. You use this string later when requesting a cell and it must be unique among the other registered cell classes of this table view. This parameter must not be an empty string or nil.
     */
    func register(_ cellClass: NSTableCellView.Type, forIdentifier identifier: NSUserInterfaceItemIdentifier) {
        self.swizzleTableViewCellRegister()
        var registeredCellsByIdentifier = self.registeredCellsByIdentifier ?? [:]
        registeredCellsByIdentifier[identifier] = cellClass
        self.registeredCellsByIdentifier = registeredCellsByIdentifier
    }
    
    /**
     The dictionary of all registered cells for view-based table view identifiers.
     
     Each key in the dictionary is the identifier string (given by ``NSUserInterfaceItemIdentifier``) used to register the cell view in the ``register(_:forIdentifier:)`` method. The value of each key is the corresponding ``NSTableCellView`` class.
     */
    internal(set) var registeredCellsByIdentifier: [NSUserInterfaceItemIdentifier : NSTableCellView.Type]?   {
        get { getAssociatedValue(key: "NSTableView_registeredCellsByIdentifier", object: self) }
        set { set(associatedValue: newValue, key: "NSTableView_registeredCellsByIdentifier", object: self) }
    }
    
    internal var didSwizzleTableViewCellRegister: Bool {
        get { getAssociatedValue(key: "NSTableView_didSwizzle_register", object: self, initialValue: false) }
        set { set(associatedValue: newValue, key: "NSTableView_didSwizzle_register", object: self) }
    }
    
    @objc internal func swizzleTableViewCellRegister(_ shouldSwizzle: Bool = true) {
        if (didSwizzleTableViewCellRegister == false) {
            didSwizzleTableViewCellRegister = true
            do {
                let hooks = [
                    try  self.hook(#selector(NSTableView.makeView(withIdentifier:owner:)),
                                           methodSignature: (@convention(c) (AnyObject, Selector, NSUserInterfaceItemIdentifier, Any?) -> (NSView?)).self,
                                           hookSignature: (@convention(block) (AnyObject, NSUserInterfaceItemIdentifier, Any?) -> (NSView?)).self) {
                    store in { (object, identifier, owner) in
                        if let registeredCellClass = self.registeredCellsByIdentifier?[identifier] {
                            if let tableCellView =        store.original(object, store.selector, identifier, owner) {
                                return tableCellView
                            } else {
                                let tableCellView = registeredCellClass.init(frame: .zero)
                                tableCellView.identifier = identifier
                                return tableCellView
                            }
                        }
                        return store.original(object, store.selector, identifier, owner)
                    }
                },
                    try  self.hook(#selector((NSTableView.register(_:forIdentifier:)) as (NSTableView) -> (NSNib?, NSUserInterfaceItemIdentifier) -> Void),
                                           methodSignature: (@convention(c) (AnyObject, Selector, NSNib?, NSUserInterfaceItemIdentifier) -> ()).self,
                                           hookSignature: (@convention(block) (AnyObject, NSNib?, NSUserInterfaceItemIdentifier) -> ()).self) {
                    store in { (object, nib, identifier) in
                        if nib == nil, var registeredCellsByIdentifier = self.registeredCellsByIdentifier, registeredCellsByIdentifier[identifier] != nil {
                            registeredCellsByIdentifier[identifier] = nil
                            self.registeredCellsByIdentifier = registeredCellsByIdentifier
                        } else {
                            return store.original(object, store.selector, nib, identifier)
                        }
                    }
                },
                ]
               try hooks.forEach({ _ = try (shouldSwizzle) ? $0.apply() : $0.revert() })
            } catch {
                Swift.print(error)
            }
        }
    }
}