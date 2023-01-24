//
//  newww.swift
//  NSCollectionViewDiffableSectionDataSource
//
//  Created by Florian Zand on 02.11.22.
//

import AppKit

extension CollectionViewDiffableDataSource {
    public struct SelectionHandlers<E> {
        public var shouldSelect: (([E]) -> [E])? = nil
        public var shouldDeselect: (([E]) -> [E])? = nil
        public var didSelect: (([E]) -> Void)? = nil
        public var didDeselect: (([E]) -> Void)? = nil
    }
    
    public struct DragdropHandlers<E> {
        var canDropOutside: (([E]) -> [E])? = nil
        var dropOutside: (([E]) -> [AnyObject])? = nil
        var canDrag: (([AnyObject]) -> Bool)? = nil
        var dragOutside: (([E]) -> [AnyObject])? = nil
        var draggingImage: (([E], NSEvent, NSPointPointer) -> NSImage?)? = nil
    }
    
    public struct HighlightHandlers<E> {
        var shouldChangeItems: (([E], NSCollectionViewItem.HighlightState) -> [E])? = nil
        var didChangeItems: (([E], NSCollectionViewItem.HighlightState) -> ())? = nil
    }
    
    public struct ReorderHandlers<E> {
        var canReorder: (([E]) -> Bool)? = nil
        var willReorder: (([E]) -> Void)? = nil
        var didReorder: (([E]) -> Void)? = nil
    }
    
    public struct PrefetchHandlers<E> {
        var willPrefetch: (([E]) -> Void)? = nil
        var didCancelPrefetching: (([E]) -> Void)? = nil
    }
    
    public struct DisplayHandlers<E> {
        var isDisplaying: (([E]) -> Void)?
        var didEndDisplaying: (([E]) -> Void)?
    }
    
    public struct QuicklookHandlers<E> {
        var preview: (([E]) -> [(element: Element, url: URL)]?)?
        var endPreviewing: (([E]) ->  [(element: Element, url: URL)]?)?
    }
    
    public struct MouseHandlers<E> {
        public var mouseClick: ((_ point: CGPoint, _ count: Int, _ element: E?) -> Void)? = nil
        public var rightMouseClick: ((_ point: CGPoint, _ count: Int, _ element: E?) -> Void)? = nil
        public var mouseDragged: ((_ point: CGPoint, _ element: E?) -> Void)? = nil
    //   var mouseEntered: ((CGPoint) -> Void)? = nil
        public var mouseMoved: ((CGPoint) -> Void)? = nil
     //   var mouseExited: ((CGPoint) -> Void)? = nil
    }
    
    public struct HoverHandlers<E> {
        var isHovering: ((E) -> Void)?
        var didEndHovering: ((E) -> Void)?
    }
    
    public struct SectionHandlers<Section> {
        var shouldCollapse: ((Section) -> Bool)?
        var willCollapse: ((Section) -> Void)?
        var shouldExpand: ((Section) -> Bool)?
        var willExpand: ((Section) -> Void)?
        var canReorder: ((Section) -> Bool)?
        var didReorder: ((Section) -> Void)?
    }
}
