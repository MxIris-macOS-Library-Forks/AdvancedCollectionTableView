//
//  NSListContentConfiguration+Image.swift
//
//
//  Created by Florian Zand on 19.06.23.
//

import AppKit
import SwiftUI
import FZSwiftUtils
import FZUIKit

public extension NSListContentConfiguration {
    /// Properties that affect the cell content configuration’s image.
    struct Accessory: Hashable {
        var leading: AccessoryProperties = {
            var properties = AccessoryProperties()
            properties.textProperties.alignment = .left
            properties.secondaryTextProperties.alignment = .left
            return properties
        }()
        
        var center: AccessoryProperties = {
            var properties = AccessoryProperties()
            properties.textProperties.alignment = .center
            properties.secondaryTextProperties.alignment = .center
            return properties
        }()
        
        var trailing: AccessoryProperties = {
            var properties = AccessoryProperties()
            properties.textProperties.alignment = .right
            properties.secondaryTextProperties.alignment = .right
            return properties
        }()
        
        var padding: CGFloat = 4.0
    }
}

public extension NSListContentConfiguration {
    /// Properties that affect the cell content configuration’s image.
    struct AccessoryProperties: Hashable {
        // MARK: Customizing content
        
        /// The primary text.
        public var text: String? = nil
        /// An attributed variant of the primary text.
        public var attributedText: AttributedString? = nil
        /// The secondary text.
        public var secondaryText: String? = nil
        /// An attributed variant of the secondary text.
        public var secondaryAttributedText: AttributedString? = nil
        /// The image.
        public var image: NSImage? = nil
        
        // MARK: Customizing appearance
        
        /// Properties for configuring the primary text.
        public var textProperties: ContentConfiguration.Text = .primary
        /// Properties for configuring the secondary text.
        public var secondaryTextProperties: ContentConfiguration.Text = .secondary
        /// Properties for configuring the image.
        public var imageProperties = ImageProperties()
        
        // MARK: Customizing layout
        
        /// The padding to 
        public var padding: CGFloat = 4.0
        /// The padding between the image and text.
        public var imageToTextPadding: CGFloat = 8.0
        /// The padding between primary and secndary text.
        public var textToSecondaryTextPadding: CGFloat = 2.0
        public var imagePosition: ImagePosition = .leading
        
        public enum ImagePosition {
            case leading
            case trailing
        }
        
        internal var hasText: Bool {
            self.text != nil || self.attributedText != nil
        }
        
        internal var hasSecondaryText: Bool {
            self.secondaryText != nil || self.secondaryAttributedText != nil
        }
        
        internal var hasContent: Bool {
            return self.image != nil
        }
        
        internal var isVisible: Bool {
            self.image != nil || self.hasText || self.hasSecondaryText
        }
    }
}