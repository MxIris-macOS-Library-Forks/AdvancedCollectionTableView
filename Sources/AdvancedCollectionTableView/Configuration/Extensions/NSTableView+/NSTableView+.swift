//
//  NSTableView+.swift
//
//
//  Created by Florian Zand on 10.12.22.
//

import AppKit
import FZSwiftUtils
import FZUIKit

extension NSTableView {
    func updateVisibleRowConfigurations() {
        visibleRows().forEach {
            $0.setNeedsAutomaticUpdateConfiguration()
            $0.setCellViewsNeedAutomaticUpdateConfiguration()
        }
    }

    var tableViewObserver: KeyValueObserver<NSTableView>? {
        get { getAssociatedValue(key: "tableViewObserver", object: self, initialValue: nil) }
        set { set(associatedValue: newValue, key: "tableViewObserver", object: self) }
    }

    var didSwizzleIsEnabled: Bool {
        get { getAssociatedValue(key: "didSwizzleIsEnabled", object: self, initialValue: false) }
        set { set(associatedValue: newValue, key: "didSwizzleIsEnabled", object: self) }
    }
    
    @objc var swizzled_isEnabled: Bool {
        get { isEnabled }
        set {
            let valueChanged = newValue != isEnabled
            self.swizzled_isEnabled = newValue
            if valueChanged, windowHandlers.isKey != nil {
                updateVisibleRowConfigurations()
            }
        }
    }
    
    func setupObservation(shouldObserve: Bool = true) {
        Swift.print("setupObservation", NSTableView.isMethodReplaced(#selector(setter: NSTableView.isEnabled)))
        if shouldObserve {
            if windowHandlers.isKey == nil {
                windowHandlers.isKey = { [weak self] windowIsKey in
                    guard let self = self else { return }
                    if windowIsKey == false {
                        self.hoveredRow = nil
                    }
                    self.updateVisibleRowConfigurations()
                }

                mouseHandlers.exited = { [weak self] _ in
                    guard let self = self else { return }
                    self.hoveredRow = nil
                }

                mouseHandlers.moved = { [weak self] event in
                    guard let self = self else { return }
                    let location = event.location(in: self)
                    if self.bounds.contains(location) {
                        let row = self.row(at: location)
                        if row != -1 {
                            self.hoveredRow = IndexPath(item: row, section: 0)
                        } else {
                            self.hoveredRow = nil
                        }
                    }
                }
            }
            if !NSTableView.isMethodReplaced(#selector(setter: NSTableView.isEnabled)) {
                do {
                    try Swizzle(NSTableView.self) {
                        #selector(setter: NSTableView.isEnabled) <-> #selector(setter: NSTableView.swizzled_isEnabled)
                    }
                                        
                    try NSTableView.replaceMethod(
                        #selector(setter: NSTableView.isEnabled),
                        methodSignature: (@convention(c)  (AnyObject, Selector, Bool) -> ()).self,
                        hookSignature: (@convention(block)  (AnyObject, Bool) -> ()).self) { store in {
                           object, isEnabled in
                            Swift.print("isEnabled", isEnabled)
                            let tableView = object as? NSTableView
                            let oldIsEnabled = tableView?.isEnabled ?? false
                           store.original(object, #selector(setter: NSTableView.isEnabled), isEnabled)
                            if let tableView = tableView, oldIsEnabled != isEnabled, tableView.windowHandlers.isKey != nil {
                                tableView.updateVisibleRowConfigurations()
                            }
                        }
                   }
                } catch {
                    Swift.debugPrint(error)
                }
            }
        } else {
            windowHandlers.isKey = nil
            mouseHandlers.exited = nil
            mouseHandlers.moved = nil
        }
    }

    var hoveredRowView: NSTableRowView? {
        if let hoveredRow = hoveredRow, let rowView = rowView(atRow: hoveredRow.item, makeIfNecessary: false) {
            return rowView
        }
        return nil
    }

    @objc dynamic var hoveredRow: IndexPath? {
        get { getAssociatedValue(key: "hoveredRow", object: self, initialValue: nil) }
        set {
            guard newValue != hoveredRow else { return }
            let previousHoveredRowView = hoveredRowView
            set(associatedValue: newValue, key: "hoveredRow", object: self)
            if let rowView = previousHoveredRowView {
                rowView.setNeedsAutomaticUpdateConfiguration()
                rowView.setCellViewsNeedAutomaticUpdateConfiguration()
            }
            if let rowView = hoveredRowView {
                rowView.setNeedsAutomaticUpdateConfiguration()
                rowView.setCellViewsNeedAutomaticUpdateConfiguration()
            }
        }
    }
}

/*
 var firstResponderObserver: KeyValueObservation? {
     get { getAssociatedValue(key: "NSTableView_firstResponderObserver", object: self, initialValue: nil) }
     set { set(associatedValue: newValue, key: "NSTableView_firstResponderObserver", object: self) }
 }

 func setupTableViewFirstResponderObserver() {
     guard firstResponderObserver == nil else { return }
     firstResponderObserver = self.observeChanges(for: \.superview?.window?.firstResponder, sendInitalValue: true, handler: { [weak self] old, new in
         guard let self = self, old != new else { return }
         guard (old == self && new != self) || (old != self && new == self) else { return }
         self.updateVisibleRowConfigurations()
     })
 }
 */
