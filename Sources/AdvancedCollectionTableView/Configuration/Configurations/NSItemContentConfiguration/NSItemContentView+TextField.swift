//
//  NSItemContentView+TextField.swift
//
//
//  Created by Florian Zand on 24.07.23.
//

import AppKit
import FZSwiftUtils
import FZUIKit

internal extension NSItemContentView {
    class ItemTextField: NSTextField, NSTextFieldDelegate {
        var properties: TextConfiguration {
            didSet {
                if oldValue != properties {
                    update()
                }
            }
        }
        
        func updateText(_ text: String?, _ attributedString: AttributedString?, _ placeholder: String?, _ attributedPlaceholder: AttributedString?) {
            if let attributedString = attributedString {
                attributedStringValue = NSAttributedString(attributedString)
            } else if let text = text {
                stringValue = text
            } else {
                stringValue = ""
            }
            
            if let attributedPlaceholder = attributedPlaceholder {
                placeholderAttributedString = NSAttributedString(attributedPlaceholder)
            } else if let placeholder = placeholder {
                placeholderString = placeholder
            } else {
                placeholderString = ""
            }
            isHidden = !(text != nil || attributedString != nil || placeholderString != nil || attributedPlaceholder != nil)
        }
        
        func update() {
            maximumNumberOfLines = properties.numberOfLines
            textColor = properties.resolvedColor()
            lineBreakMode = properties.lineBreakMode
            font = properties.font
            alignment = properties.alignment
            isSelectable = properties.isSelectable
            isEditable = properties.isEditable
        }
        
        init(properties: TextConfiguration) {
            self.properties = properties
            super.init(frame: .zero)
            delegate = self
            textLayout = .wraps
            drawsBackground = false
            backgroundColor = nil
            isBordered = false
            truncatesLastVisibleLine = true
            update()
        }
        
        var nointrinsicWidth = true
        override var intrinsicContentSize: NSSize {
            var intrinsicContentSize = super.intrinsicContentSize
            if nointrinsicWidth {
                intrinsicContentSize.width = NSView.noIntrinsicMetric
            }
            return intrinsicContentSize
        }
        
        internal var collectionViewItem: NSCollectionViewItem? {
            (firstSuperview(where: { $0.parentController is NSCollectionViewItem })?.parentController as? NSCollectionViewItem)
        }
        
        override public func becomeFirstResponder() -> Bool {
            let canBecome = super.becomeFirstResponder()
            if isEditable && canBecome {
                collectionViewItem?.isEditing = true
                previousStringValue = stringValue
            }
            return canBecome
        }
        
        public override func textDidBeginEditing(_ notification: Notification) {
            super.textDidBeginEditing(notification)
            collectionViewItem?.isEditing = true
        }
        
        public override func textDidEndEditing(_ notification: Notification) {
            super.textDidEndEditing(notification)
            previousStringValue = stringValue
            collectionViewItem?.isEditing = false
            properties.onEditEnd?(stringValue)
        }
        
        internal var previousStringValue: String = ""
        public func control(_: NSControl, textView _: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                if properties.stringValidation?(stringValue) ?? true {
                    window?.makeFirstResponder(nil)
                    return true
                } else {
                    NSSound.beep()
                }
            } else if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                stringValue = previousStringValue
                window?.makeFirstResponder(nil)
                return true
            }
            return false
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
