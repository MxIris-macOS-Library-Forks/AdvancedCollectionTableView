//
//  File.swift
//  
//
//  Created by Florian Zand on 15.12.22.
//

import AppKit
import FZExtensions

@available(macOS 12.0, *)
extension NSTableRowContentConfiguration {
    internal class ContentView: NSView, NSContentView {
        let contentView: NSView = NSView(frame: .zero)
        var configuration: NSContentConfiguration  {
            get { self.appliedConfiguration }
            set {
                if let newValue = newValue as? NSTableRowContentConfiguration {
                    self.appliedConfiguration = newValue
                }
            }
        }
        
        internal var appliedConfiguration: NSTableRowContentConfiguration {
            didSet {
                self.updateConfiguration(with: self.appliedConfiguration)
            }
        }
        
        internal func updateConfiguration(with configuration: NSTableRowContentConfiguration) {
            var roundedCorners = CACornerMask()
            if (configuration.isPreviousRowSelected == false) {
                roundedCorners.insert(.topLeft)
                roundedCorners.insert(.topRight)
            }
            if (configuration.isNextRowSelected == false) {
                roundedCorners.insert(.bottomLeft)
                roundedCorners.insert(.bottomRight)
            }
            contentView.roundedCorners = roundedCorners
            contentView.cornerRadius = configuration.cornerRadius
            contentView.backgroundColor = configuration.resolvedBackgroundColor()
            contentView.layer?.contents = configuration.image
            contentView.layer?.contentsGravity = configuration.imageProperties.scaling
        }
        
        func supports(_ configuration: NSContentConfiguration) -> Bool {
            return (configuration as? NSTableRowContentConfiguration) != nil
        }
        
        init(configuration: NSTableRowContentConfiguration) {
            self.appliedConfiguration = configuration
            super.init(frame: .zero)
            self.addSubview(withConstraint: contentView)
            contentView.wantsLayer = true
            self.updateConfiguration(with: configuration)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
