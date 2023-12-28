//
//  NSItemContentView.swift
//  
//
//  Created by Florian Zand on 07.08.23.
//

import AppKit
import FZUIKit

/// A content view for displaying collection item-based content.
public class NSItemContentView: NSView, NSContentView, EdiitingContentView {
    /// Creates an item content view with the specified content configuration.
    public init(configuration: NSItemContentConfiguration) {
        appliedConfiguration = configuration
        super.init(frame: .zero)
        isOpaque = false
        clipsToBounds = false
        stackviewConstraints = addSubview(withConstraint: stackView)
        updateConfiguration()
    }
    
    /// The current configuration of the view.
    public var configuration: NSContentConfiguration {
        get { appliedConfiguration }
        set {
            guard let newValue = newValue as? NSItemContentConfiguration else { return }
            appliedConfiguration = newValue
        }
    }
    
    /// Determines whether the view is compatible with the provided configuration.
    public func supports(_ configuration: NSContentConfiguration) -> Bool {
        configuration is NSItemContentConfiguration
    }
    
    internal lazy var textField = ItemTextField(properties: appliedConfiguration.textProperties)
    internal lazy var secondaryTextField = ItemTextField(properties: appliedConfiguration.secondaryTextProperties)
    internal lazy var contentView = ItemContentView(configuration: appliedConfiguration)
    
    internal lazy var textStackView: NSStackView = {
        let stackView = NSStackView(views: [textField, secondaryTextField])
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = appliedConfiguration.textToSecondaryTextPadding
        return stackView
    }()
    
    internal lazy var stackView: NSStackView = {
        let stackView = NSStackView(views: [contentView, textStackView])
        stackView.orientation = appliedConfiguration.contentPosition.orientation
        stackView.alignment = appliedConfiguration.contentAlignment
        stackView.spacing = appliedConfiguration.contentToTextPadding
        return stackView
    }()
    
    internal var stackviewConstraints: [NSLayoutConstraint] = []
    
    @available(*, unavailable)
    internal required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    internal var appliedConfiguration: NSItemContentConfiguration {
        didSet {
            guard oldValue != appliedConfiguration else { return }
            updateConfiguration()
        }
    }
    
    var isEditing: Bool = false {
        didSet {
            guard oldValue != isEditing else { return }
            if let tableCellView = self.tableCellView, tableCellView.contentView == self {
                tableCellView.setNeedsAutomaticUpdateConfiguration()
            } else if let tableRowView = self.tableRowView, tableRowView.contentView == self {
                tableRowView.setNeedsAutomaticUpdateConfiguration()
            } else if let collectionViewItem = self.collectionViewItem, collectionViewItem.view == self {
                collectionViewItem.setNeedsAutomaticUpdateConfiguration()
            }
        }
    }
    
    var tableCellView: NSTableCellView? {
        firstSuperview(for: NSTableCellView.self)
    }
    
    var tableRowView: NSTableRowView? {
        firstSuperview(for: NSTableRowView.self)
    }
    
    var collectionViewItem: NSCollectionViewItem? {
        firstSuperview(where: { $0.parentController is NSCollectionViewItem })?.parentController as? NSCollectionViewItem
    }
    
    internal func updateConfiguration() {
        contentView.centerYConstraint?.activate(false)
                
        textField.properties = appliedConfiguration.textProperties
        textField.updateText(appliedConfiguration.text, appliedConfiguration.attributedText, appliedConfiguration.placeholderText, appliedConfiguration.attributedPlaceholderText)
        secondaryTextField.properties = appliedConfiguration.secondaryTextProperties
        secondaryTextField.updateText(appliedConfiguration.secondaryText, appliedConfiguration.secondaryAttributedText, appliedConfiguration.secondaryPlaceholderText, appliedConfiguration.secondaryAttributedPlaceholderText)
        
        layer?.scale = appliedConfiguration.scaleTransform
        contentView.configuration = appliedConfiguration
        textStackView.spacing = appliedConfiguration.textToSecondaryTextPadding
        stackView.spacing = appliedConfiguration.contentToTextPadding
        stackView.orientation = appliedConfiguration.contentPosition.orientation
        stackView.alignment = appliedConfiguration.contentAlignment
        if appliedConfiguration.contentPosition.contentIsLeading, stackView.arrangedSubviews.first != contentView {
            stackView.removeArrangedSubview(textStackView)
            stackView.addArrangedSubview(textStackView)
        } else if appliedConfiguration.contentPosition.contentIsLeading == false, stackView.arrangedSubviews.last != contentView {
            stackView.removeArrangedSubview(contentView)
            stackView.addArrangedSubview(contentView)
        }
        stackviewConstraints.constant(appliedConfiguration.margins)
        if appliedConfiguration.contentPosition.isFirstBaseline, appliedConfiguration.image?.isSymbolImage == false {
            if appliedConfiguration.hasText {
                contentView.centerYConstraint = contentView.centerYAnchor.constraint(equalTo: textField.firstBaselineAnchor).activate()
            } else if appliedConfiguration.hasSecondaryText {
                contentView.centerYConstraint = contentView.centerYAnchor.constraint(equalTo: secondaryTextField.firstBaselineAnchor).activate()
            }
        }
        contentView.invalidateIntrinsicContentSize()
    }
}


extension NSItemContentView {
    func calculateContentViewFrame(remaining: CGRect) -> CGRect {
        var frame = remaining
        if let imageSize = appliedConfiguration.image?.size {
            switch appliedConfiguration.contentProperties.imageProperties.scaling {
            case .fit:
                frame.size = imageSize.scaled(toHeight: remaining.height)
            case .fill, .resize:
                if appliedConfiguration.contentPosition.orientation == .vertical {
                    frame = remaining
                } else {
                    frame.size = CGSize(remaining.height, remaining.height)
                }
            case .none:
                frame.size = imageSize
            }
        }
        let maxWidth = appliedConfiguration.contentProperties.maximumWidth
        let maxHeight = appliedConfiguration.contentProperties.maximumHeight
        if let maxWidth = maxWidth, let maxHeight = maxHeight, frame.width > maxWidth, frame.height > maxHeight {
            frame = frame.scaled(toFit: CGSize(maxWidth, maxHeight))
        } else if let maxWidth = maxWidth, frame.width > maxWidth {
            frame = frame.scaled(toWidth: maxWidth)
        } else if let maxHeight = maxHeight, frame.height > maxHeight {
            frame = frame.scaled(toHeight: maxHeight)
        }
        
        return frame
    }
    
    func horizontalTest() {
        let contentRegion = bounds.inset(by: appliedConfiguration.margins)
        var remainingRegion = contentRegion
        if appliedConfiguration.hasContent {
            if let imageSize = appliedConfiguration.image?.size, appliedConfiguration.contentProperties.imageProperties.scaling == .fit {
                let resized = imageSize.scaled(toHeight: remainingRegion.height)
                let contentRectArea = remainingRegion.divided(atDistance: resized.width, from: .minXEdge)
                remainingRegion = contentRectArea.remainder
                if appliedConfiguration.hasText || appliedConfiguration.hasSecondaryText {
                    remainingRegion = remainingRegion.offsetBy(dx: appliedConfiguration.contentToTextPadding, dy: 0)
                }
            } else {
                // let contentRect = remainingRegion
            }
        }
    }
    
    func test() {
        let contentRegion = bounds.inset(by: appliedConfiguration.margins)
        var remainingRegion = contentRegion
        if appliedConfiguration.hasSecondaryText, let height = secondaryTextField.cell?.cellSize(forBounds: NSRect(x: 0, y: 0, width: contentRegion.width, height: 10000)).height {
            let secondaryTextFieldArea = contentRegion.divided(atDistance: height, from: .maxYEdge)
            remainingRegion = secondaryTextFieldArea.remainder
            if appliedConfiguration.hasText {
                remainingRegion = remainingRegion.offsetBy(dx: 0, dy: appliedConfiguration.textToSecondaryTextPadding)
            } else if appliedConfiguration.hasContent {
                remainingRegion = remainingRegion.offsetBy(dx: 0, dy: appliedConfiguration.contentToTextPadding)
            }
        }
        if appliedConfiguration.hasText, let height = textField.cell?.cellSize(forBounds: NSRect(x: 0, y: 0, width: contentRegion.width, height: 10000)).height {
            let textFieldArea = contentRegion.divided(atDistance: height, from: .maxYEdge)
            remainingRegion = textFieldArea.remainder
            if appliedConfiguration.hasContent {
                remainingRegion = remainingRegion.offsetBy(dx: 0, dy: appliedConfiguration.contentToTextPadding)
            }
        }
        if appliedConfiguration.hasContent {
            if let imageSize = appliedConfiguration.image?.size, appliedConfiguration.contentProperties.imageProperties.scaling == .fit {
                var contentRect: CGRect = .zero
                contentRect.size = imageSize.scaled(toHeight: remainingRegion.height)
                contentRect.center = remainingRegion.center
            } else {
               // let contentRect = remainingRegion
            }
        }
    }
}
