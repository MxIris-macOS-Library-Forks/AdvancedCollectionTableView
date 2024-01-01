//
//  NSTableCellVew+.swift
//  
//
//  Created by Florian Zand on 14.11.22.
//

import AppKit
import FZSwiftUtils
import FZUIKit

extension NSTableCellView {
    
    // MARK: Managing the content
    
    /**
     The current content configuration of the cell.
     
     Using a content configuration, you can set the cell’s content and styling for a variety of different cell states. You can get the default configuration using ``defaultContentConfiguration()``, assign your content to the configuration, customize any other properties, and assign it to the view as the current `contentConfiguration`.
     
     Setting a content configuration replaces the view of the cell with a new content view instance from the configuration, or directly applies the configuration to the existing view if the configuration is compatible with the existing content view type.
     
     The default value is `nil`. After you set a content configuration to this property, setting this property back to `nil` replaces the current view with a new, empty view.
     */
    public var contentConfiguration: NSContentConfiguration?   {
        get { getAssociatedValue(key: "contentConfiguration", object: self) }
        set {
            set(associatedValue: newValue, key: "contentConfiguration", object: self)
            configurateContentView()
        }
    }
    
    /**
     Retrieves a default content configuration for the cell’s style. The system determines default values for the configuration according to the table view it is presented.
     
     The default content configuration has preconfigured default styling depending on the table view `style` it gets displayed in, but doesn’t contain any content. After you get the default configuration, you assign your content to it, customize any other properties, and assign it to the cell as the current content configuration.
     
     ```swift
     var content = cell.defaultContentConfiguration()
     
     // Configure content.
     content.text = "Favorites"
     content.image = NSImage(systemSymbolName: "star", accessibilityDescription: "star")
     
     // Customize appearance.
     content.imageProperties.tintColor = .purple
     
     cell.contentConfiguration = content
     ```
     
     - Returns:A default cell content configuration. The system determines default values for the configuration according to the table view and it’s style.
     */
    public func defaultContentConfiguration() -> NSListContentConfiguration {
        return NSListContentConfiguration.automatic()
    }
    
    /**
     A Boolean value that determines whether the cell automatically updates its content configuration when its state changes.
     
     When this value is `true`, the cell automatically calls `updated(for:)` on its ``contentConfiguration`` when the cell’s ``configurationState`` changes, and applies the updated configuration back to the cell. The default value is `true`.
     
     If you override ``updateConfiguration(using:)`` to manually update and customize the content configuration, disable automatic updates by setting this property to `false`.
     */
    @objc open var automaticallyUpdatesContentConfiguration: Bool {
        get { getAssociatedValue(key: "automaticallyUpdatesContentConfiguration", object: self, initialValue: true) }
        set {
            set(associatedValue: newValue, key: "automaticallyUpdatesContentConfiguration", object: self)
            setNeedsUpdateConfiguration()
        }
    }
    
    var contentView: (NSView & NSContentView)?   {
        get { getAssociatedValue(key: "_contentView", object: self) }
        set { 
            contentView?.removeFromSuperview()
            set(associatedValue: newValue, key: "_contentView", object: self)
        }
    }
    
    func configurateContentView() {
        if let contentConfiguration = contentConfiguration {
            if var contentView = contentView, contentView.supports(contentConfiguration) {
                contentView.configuration = contentConfiguration
            } else {
                let contentView = contentConfiguration.makeContentView()
                self.contentView = contentView
                translatesAutoresizingMaskIntoConstraints = false
                addSubview(withConstraint: contentView)
                setNeedsDisplay()
                contentView.setNeedsDisplay()
            }
        } else {
            contentView = nil
        }
    }
    
    // MARK: Managing the state
    
    /**
     The current configuration state of the table cell.
     
     To add your own custom state, see `NSConfigurationStateCustomKey`.
     */
    @objc open var configurationState: NSListConfigurationState {
        let state = NSListConfigurationState(isSelected: isRowSelected, isEnabled: isEnabled, isHovered: isHovered, isEditing: isEditing, isEmphasized: isEmphasized, isNextSelected: isNextRowSelected, isPreviousSelected: isPreviousRowSelected)
        return state
    }
    
    /**
     Informs the table cell to update its configuration for its current state.
     
     You call this method when you need the table cell to update its configuration according to the current configuration state. The system calls this method automatically when the cell’s ``configurationState`` changes, as well as in other circumstances that may require an update. The system might combine multiple requests into a single update.
     
     If you add custom states to the table cell’s configuration state, make sure to call this method every time those custom states change.
     */
    @objc open func setNeedsUpdateConfiguration() {
        updateConfiguration(using: configurationState)
    }
    
    func setNeedsAutomaticUpdateConfiguration() {
        if let contentConfiguration = contentConfiguration as? NSListContentConfiguration, contentConfiguration.type == .automatic, let tableView = tableView, contentConfiguration.tableViewStyle != tableView.effectiveStyle, let row = row {
            let isGroupRow = tableView.delegate?.tableView?(tableView, isGroupRow: row) ?? false
            self.contentConfiguration = contentConfiguration.tableViewStyle(tableView.effectiveStyle, isGroupRow: isGroupRow)
        }
        
        let state = configurationState
        if automaticallyUpdatesContentConfiguration, let contentConfiguration = contentConfiguration {
            self.contentConfiguration = contentConfiguration.updated(for: state)
        }
        configurationUpdateHandler?(self, state)
    }
    
    /**
     Updates the cell’s configuration using the current state.
     
     Avoid calling this method directly. Instead, use ``setNeedsUpdateConfiguration()`` to request an update.
     
     Override this method in a subclass to update the cell’s configuration using the provided state.
     */
    @objc open func updateConfiguration(using state: NSListConfigurationState) {
        if let contentConfiguration = contentConfiguration {
            self.contentConfiguration = contentConfiguration.updated(for: state)
        }
        configurationUpdateHandler?(self, state)
    }
    
    /**
     The type of block for handling updates to the cell’s configuration using the current state.
     
     - Parameters:
        - cell: The table view cell to configure.
        - state: The new state to use for updating the cell’s configuration.
     */
    public typealias ConfigurationUpdateHandler = (_ cell: NSTableCellView, _ state: NSListConfigurationState) -> Void
    
    /**
     A block for handling updates to the cell’s configuration using the current state.
     
     A configuration update handler provides an alternative approach to overriding ``updateConfiguration(using:)`` in a subclass. Set a configuration update handler to update the cell’s configuration using the new state in response to a configuration state change:
     
     ```swift
     cell.configurationUpdateHandler = { cell, state in
     var content = NSListContentConfiguration.sidebar().updated(for: state)
     content.text = "Hello world!"
     if state.isDisabled {
     content.textProperties.color = .systemGray
     }
     cell.contentConfiguration = content
     }
     ```
     
     Setting the value of this property calls ``setNeedsUpdateConfiguration()``. The system calls this handler after calling `updateConfiguration(using:)`.
     */
    @objc open var configurationUpdateHandler: ConfigurationUpdateHandler?  {
        get { getAssociatedValue(key: "configurationUpdateHandler", object: self) }
        set {
            set(associatedValue: newValue, key: "configurationUpdateHandler", object: self)
            observeTableCellView()
            setNeedsUpdateConfiguration()
        }
    }
    
    /**
     A Boolean value that specifies whether the cell view is hovered.
     
     A hovered cell view has the mouse pointer on it.
     */
    @objc open var isHovered: Bool {
        rowView?.isHovered ?? false
    }
    
    /**
     A Boolean value that specifies whether the cell view is emphasized.
     
     The cell view is emphasized when it's window is key.
     */
    @objc open var isEmphasized: Bool {
        window?.isKeyWindow ?? false
    }
    
    /**
     A Boolean value that specifies whether the cell view is enabled.
     
     The value of this property is `true` when the table view`s `isEnabled` is `true`.
     */
    @objc open var isEnabled: Bool {
        get { rowView?.isEnabled ?? true }
    }
    
    /**
     A Boolean value that indicates whether the table cell is in an editing state.

     The value of this property is `true` when the text of a list or item content configuration is currently edited.
     */
     @objc open var isEditing: Bool {
        (contentView as? EdiitingContentView)?.isEditing ?? false
    }
    
    var isNextRowSelected: Bool {
        rowView?.isNextRowSelected ?? false
    }
    
    var isPreviousRowSelected: Bool {
        rowView?.isPreviousRowSelected ?? false
    }
    
    /// The row of the cell.
    var row: Int? {
        guard let tableView = tableView else { return nil }
        var row = tableView.row(for: self)
        if row == -1 {
            row = 0
        }
        return row
    }
    
    var tableCellObserver: NSKeyValueObservation? {
        get { getAssociatedValue(key: "tableCellObserver", object: self, initialValue: nil) }
        set { set(associatedValue: newValue, key: "tableCellObserver", object: self) }
    }
    
    // Observe when the cell gets added to the row view. The row view has needs to be configurated to observe it's state like `isSelected` to update the configurationState and contentConfiguration.
    func observeTableCellView() {
        if contentConfiguration != nil || configurationUpdateHandler != nil {
            guard tableCellObserver == nil else { return }
            tableCellObserver = observeChanges(for: \.superview, handler: {old, new in
                if self.contentConfiguration is NSListContentConfiguration {
                    self.tableView?.usesAutomaticRowHeights = true
                }
                
                if let contentConfiguration = self.contentConfiguration as? NSListContentConfiguration, contentConfiguration.type == .automatic, let tableView = self.tableView, tableView.style == .automatic, contentConfiguration.tableViewStyle != tableView.effectiveStyle  {
                    self.setNeedsUpdateConfiguration()
                }
                
                self.rowView?.observeTableRowView()
                self.setNeedsUpdateConfiguration()
            })
        } else {
            tableCellObserver = nil
        }
    }
}
