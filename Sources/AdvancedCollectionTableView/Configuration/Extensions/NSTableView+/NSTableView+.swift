//
//  NSTableView+.swift
//  NSTableViewRegister
//
//  Created by Florian Zand on 10.12.22.
//


import AppKit
import FZSwiftUtils
import FZUIKit

extension NSTableView {
    /// A Boolean value that specifies whether the row view is enabled. It's `true` when the table views `isEmphasized` is `true`.
    public internal(set) var isEmphasized: Bool {
        get { getAssociatedValue(key: "_isEmphasized", object: self, initialValue: false) }
        set {
            guard newValue != self.isEmphasized else { return }
            set(associatedValue: newValue, key: "_isEmphasized", object: self)
            if newValue == false {
                self.hoveredRow = nil
            }
            updateVisibleRowConfigurations()
        }
    }
    
    func updateVisibleRowConfigurations() {
        self.visibleRows().forEach({
            $0.setNeedsAutomaticUpdateConfiguration()
            $0.setCellViewsNeedAutomaticUpdateConfiguration()
        })
    }
    
    var isEnabledObserver: NSKeyValueObservation? {
        get { getAssociatedValue(key: "tableIsEnabledObserver", object: self, initialValue: nil) }
        set { set(associatedValue: newValue, key: "tableIsEnabledObserver", object: self) }
    }
        
    func setupObservation(shouldObserve: Bool = true) {
        if shouldObserve {
            if isEnabledObserver == nil {
                isEnabledObserver = self.observeChanges(for: \.isEnabled, handler: { [weak self] old, new in
                    guard let self = self, old != new else { return }
                    self.updateVisibleRowConfigurations()
                })
            }
            if (observingView == nil) {
                observingView = ObservingView()
                addSubview(withConstraint: self.observingView!)
                observingView!.sendToBack()
                observingView?.windowHandlers.isKey = { [weak self] windowIsKey in
                    guard let self = self else { return }
                    self.isEmphasized = windowIsKey
                }
                
                observingView?.mouseHandlers.exited = { [weak self] event in
                    guard let self = self else { return true }
                    self.hoveredRow = nil
                    return true
                }
                
                observingView?.mouseHandlers.moved = { [weak self] event in
                    guard let self = self else { return true }
                    let location = event.location(in: self)
                    if self.bounds.contains(location) {
                        let row = self.row(at: location)
                        if row != -1 {
                            self.hoveredRow = IndexPath(item: row, section: 0)
                        } else {
                            self.hoveredRow = nil
                        }
                    }
                    return true
                }
            }
        } else {
            observingView?.removeFromSuperview()
            observingView = nil
        }
    }
    
    var observingView: ObservingView? {
        get { getAssociatedValue(key: "NSTableView_observingView", object: self) }
        set { set(associatedValue: newValue, key: "NSTableView_observingView", object: self)
        }
    }
    
    var hoveredRowView: NSTableRowView? {
        if let hoveredRow = hoveredRow, let rowView = self.rowView(atRow: hoveredRow.item, makeIfNecessary: false) {
            return rowView
        }
        return nil
    }
    
    @objc dynamic var hoveredRow: IndexPath? {
        get { getAssociatedValue(key: "NSTableView_hoveredRow", object: self, initialValue: nil) }
        set {
            guard newValue != hoveredRow else { return }
            let previousHoveredRowView = hoveredRowView
            set(associatedValue: newValue, key: "NSTableView_hoveredRow", object: self)
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
var firstResponderObserver: NSKeyValueObservation? {
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
