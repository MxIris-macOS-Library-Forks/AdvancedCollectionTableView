//
//  NSItemConfigurationState.swift
//
//
//  Created by Florian Zand on 02.09.22.
//

import AppKit
import Foundation
import FZUIKit

/**
 A structure that encapsulates an collection-based item’s state.

 Am item configuration encapsulates states like selected, highlighted, emphasized or hovered.

 You can use a item configuration state with background and content configurations to obtain the default appearance for a specific state.

 Typically, you don’t create a configuration state yourself. To obtain a configuration state, use `NSCollectionViewItems` ``AppKit/NSCollectionViewItem/configurationUpdateHandler-swift.property`` or override the ``AppKit/NSCollectionViewItem/updateConfiguration(using:)`` method in your item subclass and use the state parameter. Outside of this method, you can get a item’s configuration state by using its ``AppKit/NSCollectionViewItem/configurationState`` property.

 You can create your own custom states to add to a item configuration state by defining a custom state key using `NSConfigurationStateCustomKey`.
 */
public struct NSItemConfigurationState: NSConfigurationState, Hashable {
    /// A Boolean value that indicates whether the item is selected.
    public var isSelected: Bool = false {
        didSet {
            self["isSelected"] = isSelected
        }
    }

    /// A value that indicates the item's highlight state.
    public var highlight: NSCollectionViewItem.HighlightState = .none

    /**
     A Boolean value that indicates whether the item is in an editing state.

     The value of this property is `true`, if the text of a list or item content configuration is being edited.
     */
    public var isEditing: Bool = false

    /**
     A Boolean value that indicates whether the item is in an active state.

     The value of this property is `true`, if it's window is focused.
     */
    public var isActive: Bool = false {
        didSet {
            self["isActive"] = isActive
        }
    }

    /**
     A Boolean value that indicates whether the item is in a hovered state.

     The value of this property is `true`, if the mouse is hovering the item.
     */
    public var isHovered: Bool = false
    
    /// A Boolean value that indicates whether the item is reordering.
    public var isReordering: Bool = false
    
    /// A Boolean value that indicates whether the item is the target of a drop operation.
    public var isDropTarget: Bool = false

    /// A Boolean value that indicates whether the item is in a enabled state.
    var isEnabled: Bool = true

    /// A Boolean value that indicates whether the item is in a focused state.
    var isFocused: Bool = false

    /// A Boolean value that indicates whether the item is in a expanded state.
    var isExpanded: Bool = false

    var customStates = [NSConfigurationStateCustomKey: AnyHashable]()

    /// Accesses custom states by key.
    public subscript(key: NSConfigurationStateCustomKey) -> AnyHashable? {
        get { customStates[key] }
        set { customStates[key] = newValue }
    }

    public init(
        isSelected: Bool = false,
        highlight: NSCollectionViewItem.HighlightState = .none,
        isEditing: Bool = false,
        isActive: Bool = false,
        isHovered: Bool = false,
        isReordering: Bool = false,
        isDropTarget: Bool = false
    ) {
        self.isSelected = isSelected
        self.highlight = highlight
        self.isEditing = isEditing
        self.isActive = isActive
        self.isHovered = isHovered
        self.isReordering = isReordering
        self.isDropTarget = isDropTarget
        self["isSelected"] = isSelected
        self["isActive"] = isActive
    }

    init(isSelected: Bool,
         isEnabled: Bool,
         isFocused: Bool,
         isHovered: Bool,
         isEditing: Bool,
         isExpanded: Bool,
         highlight: NSCollectionViewItem.HighlightState,
         isActive: Bool,
         isReordering: Bool,
         isDropTarget: Bool,
         customStates _: [NSConfigurationStateCustomKey: AnyHashable] = [:])
    {
        self.isSelected = isSelected
        self.isEnabled = isEnabled
        self.isFocused = isFocused
        self.isHovered = isHovered
        self.isEditing = isEditing
        self.isExpanded = isExpanded
        self.highlight = highlight
        self.isActive = isActive
        self.isReordering = isReordering
        self.isDropTarget = isDropTarget
        self["isSelected"] = isSelected
        self["isActive"] = isActive
        self["isItemState"] = true
    }
}

extension NSItemConfigurationState: ReferenceConvertible {
    /// The Objective-C type for this state.
    public typealias ReferenceType = __NSItemConfigurationStateObjc

    public var description: String {
        """
        NSItemConfigurationState(
            isEnabled: \(isEnabled)
            isHovered: \(isHovered)
            isEditing: \(isEditing)
            highlight: \(highlight.rawValue)
            isActive: \(isActive)
            customStates: \(customStates)
        )
        """
    }

    public var debugDescription: String {
        description
    }

    public func _bridgeToObjectiveC() -> __NSItemConfigurationStateObjc {
        return __NSItemConfigurationStateObjc(isSelected: isSelected, isEnabled: isEnabled, isHovered: isHovered, isEditing: isEditing, highlight: highlight, isActive: isActive, isFocused: isFocused, isExpanded: isExpanded, isReordering: isReordering, isDropTarget: isDropTarget, customStates: customStates)
    }

    public static func _forceBridgeFromObjectiveC(_ source: __NSItemConfigurationStateObjc, result: inout NSItemConfigurationState?) {
        result = NSItemConfigurationState(isSelected: source.isSelected, isEnabled: source.isEnabled, isFocused: source.isFocused, isHovered: source.isHovered, isEditing: source.isEditing, isExpanded: source.isExpanded, highlight: source.highlight, isActive: source.isActive, isReordering: source.isReordering, isDropTarget: source.isDropTarget, customStates: source.customStates)
    }

    public static func _conditionallyBridgeFromObjectiveC(_ source: __NSItemConfigurationStateObjc, result: inout NSItemConfigurationState?) -> Bool {
        _forceBridgeFromObjectiveC(source, result: &result)
        return true
    }

    public static func _unconditionallyBridgeFromObjectiveC(_ source: __NSItemConfigurationStateObjc?) -> NSItemConfigurationState {
        if let source = source {
            var result: NSItemConfigurationState?
            _forceBridgeFromObjectiveC(source, result: &result)
            return result!
        }
        return NSItemConfigurationState()
    }
}

/// The `Objective-C` class for ``NSItemConfigurationState``.
public class __NSItemConfigurationStateObjc: NSObject, NSCopying {
    let isSelected: Bool
    let highlight: NSCollectionViewItem.HighlightState
    let isEditing: Bool
    let isActive: Bool
    let isHovered: Bool
    let isEnabled: Bool
    let isFocused: Bool
    let isExpanded: Bool
    let isReordering: Bool
    let isDropTarget: Bool
    let customStates: [NSConfigurationStateCustomKey: AnyHashable]

    init(isSelected: Bool, isEnabled: Bool, isHovered: Bool, isEditing: Bool, highlight: NSCollectionViewItem.HighlightState, isActive: Bool, isFocused: Bool, isExpanded: Bool, isReordering: Bool, isDropTarget: Bool, customStates: [NSConfigurationStateCustomKey: AnyHashable] = [:]) {
        self.isSelected = isSelected
        self.isEnabled = isEnabled
        self.isHovered = isHovered
        self.isEditing = isEditing
        self.highlight = highlight
        self.isActive = isActive
        self.isFocused = isFocused
        self.isExpanded = isExpanded
        self.isReordering = isReordering
        self.isDropTarget = isDropTarget
        self.customStates = customStates
        super.init()
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        __NSItemConfigurationStateObjc(isSelected: isSelected, isEnabled: isEnabled, isHovered: isHovered, isEditing: isEditing, highlight: highlight, isActive: isActive, isFocused: isFocused, isExpanded: isExpanded, isReordering: isReordering, isDropTarget: isDropTarget, customStates: customStates)
    }
}

/*
 /// The emphasized state.
 public struct EmphasizedState: OptionSet, Hashable {
 public let rawValue: UInt
 /// The window of the item is key.
 public static let isKeyWindow = EmphasizedState(rawValue: 1 << 0)
 /// The collection view of the item is first responder.
 public static let isFirstResponder = EmphasizedState(rawValue: 1 << 1)

 /// Creates a units structure with the specified raw value.
 public init(rawValue: UInt) {
 self.rawValue = rawValue
 }
 }

 /// The emphasized state.
 public var emphasizedState: EmphasizedState = []
 */
