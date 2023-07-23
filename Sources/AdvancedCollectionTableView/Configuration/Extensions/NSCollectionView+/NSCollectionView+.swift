//
//  NSCollectionView.swift
//  NSHostingViewSizeInTableView
//
//  Created by Florian Zand on 01.11.22.
//

import AppKit
import FZSwiftUtils
import FZUIKit

public extension NSCollectionView {
    internal var isEmphasized: Bool {
        get { getAssociatedValue(key: "NSCollectionView_isEmphasized", object: self, initialValue: false) }
        set {
            guard newValue != isEmphasized else { return }
            set(associatedValue: newValue, key: "NSCollectionView_isEmphasized", object: self)
            if newValue == false {
                self.removeHoveredItem()
            }
            self.visibleItems().forEach({$0.setNeedsAutomaticUpdateConfiguration()})
        }
    }
    
    var isEnabled: Bool {
        get { getAssociatedValue(key: "NSCollectionView_isEnabled", object: self, initialValue: true) }
        set {
            set(associatedValue: newValue, key: "NSCollectionView_isEnabled", object: self)
            self.visibleItems().forEach({$0.isEnabled = newValue })
        }
    }
    
    var _isFirstResponder: Bool {
        get { getAssociatedValue(key: "_NSCollectionView__isFirstResponder", object: self, initialValue: false) }
        set {
            guard newValue != _isFirstResponder else { return }
            set(associatedValue: newValue, key: "_NSCollectionView__isFirstResponder", object: self)
            self.visibleItems().forEach({$0.setNeedsAutomaticUpdateConfiguration() })
        }
    }
    
    internal func setupCollectionViewFirstResponderObserver() {
        self.firstResponderHandler = { isFirstResponder in
            self._isFirstResponder = isFirstResponder
        }
    }
}

/*
 internal var trackDisplayingItems: Bool {
     get { getAssociatedValue(key: "NSCollectionView_trackDisplayingItems", object: self, initialValue: false) }
     set {
         set(associatedValue: newValue, key: "NSCollectionView_trackDisplayingItems", object: self)
         self.updateDisplayingItemsTracking()
     }
 }
 
 internal func updateDisplayingItemsTracking() {
     guard let scrollView = self.enclosingScrollView else {  return }
     let clipView = scrollView.contentView
     if (self.trackDisplayingItems) {
         clipView.postsBoundsChangedNotifications = true
         NotificationCenter.default.addObserver(self, selector: #selector(didScroll), name: NSView.boundsDidChangeNotification, object: clipView)
     } else {
         clipView.postsBoundsChangedNotifications = false
         NotificationCenter.default.removeObserver(self, name: NSView.boundsDidChangeNotification, object: clipView)
     }
 }
 
 @objc func didScroll() {
     
 }
 */

/*
 internal func updateItemHoverState(_ event: NSEvent) {
 if let mouseItem = mouseItem, mouseItem.isHovered == false {
     mouseItem.isHovered = true
     hoveredItem = mouseItem
 }

 let visibleItems = self.visibleItems()
 let previousHoveredItems = visibleItems.filter({$0.isHovered && $0 != mouseItem})
 previousHoveredItems.forEach({$0.isHovered = false })
 }
 
 internal func setupSelectionObserver(shouldObserve: Bool = true) {
     if shouldObserve {
         if selectionObserver == nil {
             selectionObserver = self.observeChange(\.selectionIndexPaths) { object, previousIndexes, newIndexes in
                 var itemIndexPaths: [IndexPath] = []
                 
                 let added = newIndexes.symmetricDifference(previousIndexes)
                 let removed = previousIndexes.symmetricDifference(newIndexes)

                 itemIndexPaths.append(contentsOf: added)
                 itemIndexPaths.append(contentsOf: removed)
                 itemIndexPaths = itemIndexPaths.uniqued()
                 let items = itemIndexPaths.compactMap({self.item(at: $0)})
                 items.forEach({ $0.setNeedsUpdateConfiguration() })
             }
         }
     } else {
         selectionObserver?.invalidate()
         selectionObserver = nil
     }
 }
 
 internal var selectionObserver: NSKeyValueObservation? {
     get { getAssociatedValue(key: "NSCollectionItem_Observer", object: self, initialValue: nil) }
     set { set(associatedValue: newValue, key: "NSCollectionItem_Observer", object: self)
     }
}
 */
