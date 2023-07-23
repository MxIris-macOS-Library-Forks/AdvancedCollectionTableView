//
//  NSTableView+ObservingView.swift
//
//
//  Created by Florian Zand on 08.06.23.
//

import AppKit
import FZSwiftUtils
import FZUIKit

public extension NSTableView {
    /// Handlers that get called whenever the mouse is hovering a rnow.
    struct RowHoverHandlers {
        /// The handler that gets called whenever the mouse is hovering a row.
        var isHovering: ((_ row: NSTableRowView) -> ())?
        /// The handler that gets called whenever the mouse did end hovering a row.
        var didEndHovering: ((_ row: NSTableRowView) -> ())?
    }
    
    /// Handlers that get called whenever the mouse is hovering a rnow.
    var rowHoverHandlers: RowHoverHandlers {
        get { getAssociatedValue(key: "NSTableView_rowHoverHandlers", object: self, initialValue: RowHoverHandlers()) }
        set { set(associatedValue: newValue, key: "NSTableView_rowHoverHandlers", object: self)
            let shouldObserve = (newValue.isHovering != nil || newValue.didEndHovering != nil)
            self.setupObservingView(shouldObserve: shouldObserve)
        }
    }
}

internal extension NSTableView {
    func updateHoveredRow(_ mouseLocation: CGPoint) {
        let newHoveredRowView = self.rowView(at: mouseLocation)
        self.hoveredRowView = newHoveredRowView
    }
    
    func setupObservingView(shouldObserve: Bool = true) {
        if shouldObserve {
            if (self.observingView == nil) {
                self.observingView = ObservingView()
                self.addSubview(withConstraint: self.observingView!)
                self.observingView!.sendToBack()
                self.observingView?.windowHandlers.isKey = { [weak self] windowIsKey in
                    guard let self = self else { return }
                    self.isEmphasized = windowIsKey
                }
                
                self.observingView?.mouseHandlers.exited = { [weak self] event in
                    guard let self = self else { return true }
                    self.removeHoveredRow()
                    return true
                }
                
                self.observingView?.mouseHandlers.moved = { [weak self] event in
                    guard let self = self else { return true }
                    let location = event.location(in: self)
                    if self.bounds.contains(location) {
                        self.updateHoveredRow(location)
                    }
                    return true
                }
            }
        } else {
            self.observingView?.removeFromSuperview()
            self.observingView = nil
        }
    }
        
    var observingView: ObservingView? {
        get { getAssociatedValue(key: "NSTableView_observingView", object: self) }
        set { set(associatedValue: newValue, key: "NSTableView_observingView", object: self)
        }
    }
    
    var hoveredRowView: NSTableRowView? {
        get { getAssociatedValue(key: "NSTableView_hoveredRowView", object: self, initialValue: nil) }
        set {
            guard newValue != hoveredRowView else { return }
            let previousHovered = hoveredRowView
            set(weakAssociatedValue: newValue, key: "NSTableView_hoveredRowView", object: self)
            
            if let previousHovered = previousHovered {
                previousHovered.setNeedsAutomaticUpdateConfiguration()
                previousHovered.setCellViewsNeedAutomaticUpdateConfiguration()
                rowHoverHandlers.didEndHovering?(previousHovered)
            }
            
            if let hoveredRowView = newValue {
                hoveredRowView.setNeedsAutomaticUpdateConfiguration()
                hoveredRowView.setCellViewsNeedAutomaticUpdateConfiguration()
                rowHoverHandlers.isHovering?(hoveredRowView)
            }
        }
    }
}
