//
//  NSListContentConfiguration.swift
//
//
//  Created by Florian Zand on 18.06.23.
//

import AppKit
import FZUIKit

/**
 A content configuration for a list-based content view.

 A list content configuration describes the styling and content for an individual element that might appear in a list, like a cell, header, or footer. Using a list content configuration, you can obtain system default styling for a variety of different view states. You fill the configuration with your content, and then assign it directly to table cells via ``AppKit/NSTableCellView/contentConfiguration``, or to your own custom list content view (``NSListContentView``).

 To get a list configuration that has preconfigured default styling based on the table view it is presented, use table cell's  ``AppKit/NSTableCellView/defaultContentConfiguration()``.

 ```swift
 var content = tableCell.defaultContentConfiguration()

 // Configure content.
 content.image = NSImage(systemSymbolName: "star")
 content.text = "Favorites"

 // Customize appearance.
 content.imageProperties.tintColor = .purple

 tableCell.contentConfiguration = content
 ```
 */
public struct NSListContentConfiguration: NSContentConfiguration, Hashable {
    // MARK: Customizing content

    /**
     The primary text.

     If you configurate the value with a non-`nil` value, ``attributedText`` is set to `nil`.
     */
    public var text: String? {
        didSet {
            guard text != nil else { return }
            attributedText = nil
        }
    }

    /**
     An attributed variant of the primary text.

     If you configurate the value with a non-`nil` value, ``text`` is set to `nil`.
     */
    public var attributedText: AttributedString? {
        didSet {
            guard attributedText != nil else { return }
            text = nil
        }
    }

    /**
     The primary placeholder text.

     If you configurate the value with a non-`nil` value, ``attributedPlaceholderText`` ist set to `nil`.
     */
    public var placeholderText: String? {
        didSet {
            guard placeholderText != nil else { return }
            attributedPlaceholderText = nil
        }
    }

    /**
     An attributed variant of the primary placeholder text.

     If you configurate the value with a non-`nil` value, ``placeholderText`` is set to `nil`.
     */
    public var attributedPlaceholderText: AttributedString? {
        didSet {
            guard attributedPlaceholderText != nil else { return }
            placeholderText = nil
        }
    }

    /**
     The secondary text.

     If you configurate the value with a non-`nil` value, ``secondaryAttributedText`` is set to `nil`.
     */
    public var secondaryText: String? {
        didSet {
            guard secondaryText != nil else { return }
            secondaryAttributedText = nil
        }
    }

    /**
     An attributed variant of the secondary text.

     If you configurate the value with a non-`nil` value, ``secondaryText`` is set to `nil`.
     */
    public var secondaryAttributedText: AttributedString? {
        didSet {
            guard secondaryAttributedText != nil else { return }
            secondaryText = nil
        }
    }

    /**
     The secondary placeholder text.

     If you configurate the value with a non-`nil` value, ``secondaryAttributedPlaceholderText`` is set to `nil`.
     */
    public var secondaryPlaceholderText: String? {
        didSet {
            guard secondaryPlaceholderText != nil else { return }
            secondaryAttributedPlaceholderText = nil
        }
    }

    /**
     An attributed variant of the secondary placeholder text.

     If you configurate the value with a non-`nil` value, ``secondaryPlaceholderText`` is set to `nil`.
     */
    public var secondaryAttributedPlaceholderText: AttributedString? {
        didSet {
            guard secondaryAttributedPlaceholderText != nil else { return }
            secondaryPlaceholderText = nil
        }
    }

    /// The image.
    public var image: NSImage?

    /// The badge.
    public var badge: Badge?
    
    /// The text for the tooltip.
    public var toolTip: String? = nil

    // MARK: Customizing appearance

    /// Properties for configuring the primary text.
    public var textProperties: TextProperties = .primary

    /// Properties for configuring the secondary text.
    public var secondaryTextProperties: TextProperties = .secondary

    /// Properties for configuring the image.
    public var imageProperties = ImageProperties()

    // MARK: Customizing layout

    /// The padding between the image and text.
    public var imageToTextPadding: CGFloat = 8.0

    /// The padding between primary and secndary text.
    public var textToSecondaryTextPadding: CGFloat = 2.0

    /// The padding between the text and badge.
    public var textToBadgePadding: CGFloat = 6.0

    /// The margins between the content and the edges of the list view.
    public var margins = NSDirectionalEdgeInsets(top: 6.0, leading: 4.0, bottom: 6.0, trailing: 4.0)
    
    /// The accesories.
    var accesories: [Accessory] = []
    
    var topAccesories: [Accessory] {
        accesories.filter({ $0.position == .top })
    }
    
    var bottomAccesories: [Accessory] {
        accesories.filter({ $0.position == .bottom })
    }

    // MARK: Creating item configurations

    /// Creates a list content configuration for a table view with plain style.
    /**
     Creates a list content configuration for a table view with plain style.

     - parameter imageColor: The color of a template or symbol image. The default value is `monochrome(.controlAccentColor)`.
          */
    public static func plain(imageColor: ImageSymbolConfiguration.ColorConfiguration = .monochrome(.controlAccentColor)) -> NSListContentConfiguration {
        var configuration = sidebar(.body, color: imageColor)
        configuration.imageToTextPadding = 6.0
        configuration.imageProperties.position = .leading(.firstBaseline)
        configuration.imageProperties.sizing = .firstTextHeight
        configuration.margins = NSDirectionalEdgeInsets(top: 2.0, leading: 2.0, bottom: 2.0, trailing: 2.0)
        return configuration
    }

    /**
     Creates a list content configuration for a sidebar table view (source style).

     - parameter imageColor: The color of a template or symbol image. The default value is `monochrome(.controlAccentColor)`.
     */
    public static func sidebar(imageColor: ImageSymbolConfiguration.ColorConfiguration = .monochrome(.controlAccentColor)) -> NSListContentConfiguration {
        sidebar(.body, color: imageColor)
    }

    /**
     Creates a header list content configuration for a sidebar table view (source style).

     - parameter imageColor: The color of a template or symbol image. The default value is `monochrome(.controlAccentColor)`.
     */
    public static func sidebarHeader(imageColor: ImageSymbolConfiguration.ColorConfiguration = .monochrome(.controlAccentColor)) -> NSListContentConfiguration {
        var configuration = NSListContentConfiguration()
        configuration.textProperties.font = .subheadline.weight(.bold)
        configuration.textProperties.color = .tertiaryLabelColor
        configuration.imageProperties.tintColor = .tertiaryLabelColor
        configuration.imageProperties.position = .leading(.firstBaseline)
        configuration.imageProperties.sizing = .firstTextHeight
        configuration.imageProperties.symbolConfiguration = .init(font: .textStyle(.subheadline, weight: .bold), color: imageColor)
        configuration.margins = .init(top: 2.0, leading: 4.0, bottom: 2.0, trailing: 4.0)
        //  configuration.margins = .init(top: 2.0, leading: 2.0, bottom: 2.0, trailing: 2.0)
        return configuration
    }

    /**
     Creates a large list content configuration for a sidebar table view (source style).

     - parameter imageColor: The color of a template or symbol image. The default value is `monochrome(.controlAccentColor)`.
     */
    public static func sidebarLarge(imageColor: ImageSymbolConfiguration.ColorConfiguration = .monochrome(.controlAccentColor)) -> NSListContentConfiguration {
        var configuration = sidebar(.title3, color: imageColor)
        configuration.margins = .init(top: 8.0, leading: 4.0, bottom: 8.0, trailing: 4.0)
        return configuration
    }

    /**
     Creates a plain list content configuration with text.

     - Parameter text: The text.
     */
    public static func text(_ text: String) -> Self {
        var configuration: Self = .plain()
        configuration.text = text
        return configuration
    }

    /**
     Creates a plain list content configuration with editable text.

     - Parameters:
        - text: The text.
        - placeholderText: The placeholder text.
        - onTextEditEnd: The handler that gets called when the text changes.
        - stringValidation: The Handler that determines whether the edited string is valid.
     */
    public static func editableText(_ text: String?, placeholderText: String?, onTextEditEnd: @escaping (String) -> Void, stringValidation: ((String) -> (Bool))? = nil) -> Self {
        var configuration: Self = .plain()
        configuration.text = text
        configuration.placeholderText = placeholderText
        configuration.textProperties.isEditable = true
        configuration.textProperties.isSelectable = true
        configuration.textProperties.onEditEnd = onTextEditEnd
        configuration.textProperties.stringValidation = stringValidation
        return configuration
    }

    /// Creates a list content configuration.
    public init() {}

    var type: ListItemType = .normal
    var tableViewStyle: NSTableView.Style?
    var isEnabled: Bool = true

    enum ListItemType: Int, Hashable {
        case normal
        case automatic
        case automaticHeader
        
        var isAutomatic: Bool {
            self == .automatic || self == .automaticHeader
        }
    }

    var hasText: Bool {
        text != nil || attributedText != nil
    }

    var hasSecondaryText: Bool {
        secondaryText != nil || secondaryAttributedText != nil
    }

    var hasContent: Bool {
        image != nil
    }

    // MARK: Creating a content view

    /// Creates a new instance of the content view using the configuration.
    public func makeContentView() -> NSView & NSContentView {
        NSListContentView(configuration: self)
    }

    // MARK: Updating the configuration

    /// Generates a configuration for the specified state by applying the configuration’s default values for that state to any properties that you don’t customize.
    public func updated(for state: NSConfigurationState) -> NSListContentConfiguration {
        var configuration = self
        configuration.isEnabled = (state as? NSListConfigurationState)?.isEnabled ?? true
        return self
    }
}

extension NSListContentConfiguration {
    static func automatic() -> NSListContentConfiguration {
        var configuration = sidebar(.body, color: .monochrome(.controlAccentColor))
        configuration.type = .automatic
        configuration.imageProperties.position = .leading(.firstBaseline)
        configuration.imageProperties.sizing = .firstTextHeight
        return configuration
    }

    static func automaticHeader() -> NSListContentConfiguration {
        var configuration = sidebar(.body, color: .monochrome(.controlAccentColor))
        configuration.type = .automaticHeader
        configuration.imageProperties.position = .leading(.firstBaseline)
        configuration.imageProperties.sizing = .firstTextHeight
        return configuration
    }
    
    mutating func updated(from configuration: NSListContentConfiguration) -> NSListContentConfiguration {
        guard type.isAutomatic, configuration.type.isAutomatic, let tableViewStyle = configuration.tableViewStyle, tableViewStyle != .automatic else { return self }
        type = configuration.type
        return updated(for: tableViewStyle)
    }
    
    func updated(for tableView: NSTableView?) -> NSListContentConfiguration? {
        guard let tableView = tableView, type.isAutomatic, tableView.effectiveStyle != .automatic, tableView.effectiveStyle != tableViewStyle else { return nil }
        return updated(for: tableView.effectiveStyle)
    }

    func updated(for style: NSTableView.Style) -> NSListContentConfiguration {
        var configuration = self
        configuration.tableViewStyle = style
        switch style {
        case .automatic: break
        case .sourceList:
            if type == .automaticHeader {
                configuration.textProperties.font = .subheadline.weight(.bold)
                configuration.textProperties.color = .tertiaryLabelColor
                // configuration.secondaryTextProperties = configuration.textProperties
                configuration.imageProperties.tintColor = .tertiaryLabelColor
                configuration.imageProperties.position = .leading(.firstBaseline)
                configuration.imageProperties.sizing = .firstTextHeight
                configuration.imageProperties.symbolConfiguration = .init(font: .textStyle(.subheadline, weight: .bold), color: .monochrome)
                configuration.margins = .init(top: 2.0, leading: 2.0, bottom: 2.0, trailing: 2.0)
            } else {
                configuration.textProperties.font = .body
                configuration.secondaryTextProperties.font = .body
                configuration.imageProperties.symbolConfiguration = .init(font: .textStyle(.body), color: .monochrome)
                configuration.imageToTextPadding = 3.0
                configuration.margins = .init(top: 6.0, leading: 4.0, bottom: 6.0, trailing: 4.0)
            }
        default:
            configuration.textProperties.font = .body
            configuration.secondaryTextProperties.font = .body
            configuration.imageToTextPadding = 6.0
            configuration.textProperties.maximumNumberOfLines = 0
            configuration.secondaryTextProperties.maximumNumberOfLines = 0
            configuration.imageProperties.symbolConfiguration = .init(font: .textStyle(.body))
            configuration.imageProperties.symbolConfiguration = .init(font: .textStyle(.body), color: .monochrome)
            configuration.margins = .init(top: 2.0, leading: type == .automaticHeader ? 2.0 : 4.0  , bottom: 2.0, trailing: 2.0)
        }
        return configuration
    }

    static func sidebar(_ style: NSFont.TextStyle, weight: NSFont.Weight = .regular, color: ImageSymbolConfiguration.ColorConfiguration) -> NSListContentConfiguration {
        var configuration = NSListContentConfiguration()
        configuration.imageProperties.position = .leading(.firstBaseline)
        configuration.textProperties.font = .systemFont(style).weight(weight)
        configuration.textProperties.maximumNumberOfLines = 1
        configuration.secondaryTextProperties.maximumNumberOfLines = 0
        configuration.secondaryTextProperties.font = .systemFont(style).weight(weight)
        configuration.imageProperties.symbolConfiguration = .font(style, weight: weight)
        configuration.imageProperties.tintColor = color.primary
        configuration.imageProperties.sizing = .firstTextHeight
        configuration.imageProperties.symbolConfiguration = .font(style).color(color)
        configuration.imageToTextPadding = 3.0
        configuration.margins = .init(top: 6.0, leading: 4.0, bottom: 6.0, trailing: 4.0)
        return configuration
    }
}
