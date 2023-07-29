//
//  SupplementaryRegistration.swift
//  
//
//  Created by Florian Zand on 19.05.22.
//

import AppKit
import FZSwiftUtils
import FZUIKit
           
public extension NSCollectionView {
    /**
    Dequeues a configured reusable supplementary view object.
     
     - Parameters:
        - registration: The supplementary registration for configuring the supplementary view object. See NSCollectionView.SupplementaryRegistration.
        - indexPath: The index path that specifies the location of the supplementary view in the collection view.

     - returns: A configured reusable supplementary view object.
     */
    func makeSupplementaryView<V>(using registration: SupplementaryRegistration<V>, for indexPath: IndexPath) -> V {
        return registration.makeSupplementaryView(self, indexPath) as! V
    }
}

public protocol NSCollectionViewSupplementaryProvider {
    func makeSupplementaryView(_ collectionView: NSCollectionView, _ indexPath: IndexPath) -> (NSView & NSCollectionViewElement)
    var elementKind: String { get }
}

public extension NSCollectionView {
    /**
     A registration for the collection view’s supplementary views.
     
     Use a supplementary registration to register supplementary views, like headers and footers, with your collection view and configure each view for display. You create a supplementary registration with your supplementary view type and data item type as the registration’s generic parameters, passing in a registration handler to configure the view. In the registration handler, you specify how to configure the content and appearance of that type of supplementary view.
     
     The following example creates a supplementary registration for a custom header view subclass.
     
     ```
     let headerRegistration = NSCollectionView.SupplementaryRegistration
         <HeaderView>(elementKind: "Header") {
         supplementaryView, string, indexPath in
         supplementaryView.label.text = "\(string) for section \(indexPath.section)"
         supplementaryView.backgroundColor = .lightGray
     }
     ```
     
     After you create a supplementary registration, you pass it in to makeSupplementaryView(using:for:), which you call from your data source’s supplementaryViewProvider.
     
     ```
     dataSource.supplementaryViewProvider = { supplementaryView, elementKind, indexPath in
         return collectionView.makeSupplementaryView(using: headerRegistration,
                                                                      for: indexPath)
     }
     ```
     
     You don’t need to item call *register(_:forSupplementaryViewOfKind:withIdentifier)*, *register(_:nib:)* or *register(_:forItemWithIdentifier:)*.  The registration occurs automatically when you pass the supplementary view registration to makeSupplementaryView(using:for:).
     
     - Important: Do not create your item registration inside a *NSCollectionViewDiffableDataSource.SupplementaryViewProvider* closure; doing so prevents item reuse.
    */
    class SupplementaryRegistration<SupplementaryView>: NSCollectionViewSupplementaryProvider where SupplementaryView: (NSView & NSCollectionViewElement)  {
        
        internal let identifier: NSUserInterfaceItemIdentifier
        internal let nib: NSNib?
        internal let handler: Handler
        public let elementKind: SupplementaryElementKind
        
        // MARK: Creating a supplementary registration
                
        public init(elementKind: SupplementaryElementKind, handler: @escaping Handler) {
            self.handler = handler
            self.elementKind = elementKind
            self.nib = nil
            self.identifier = .init(String(describing: SupplementaryView.self) + elementKind)
        }
        
        public init(nib: NSNib, elementKind: SupplementaryElementKind, handler: @escaping Handler) {
            self.nib = nib
            self.elementKind = elementKind
            self.handler = handler
            self.identifier = .init(String(describing: SupplementaryView.self) + String(describing: nib.self) + elementKind)
        }
        
        /// A closure that handles the supplementary registration and configuration.
        public typealias Handler = ((SupplementaryView, SupplementaryElementKind, IndexPath)->(Void))
        
        public func makeSupplementaryView(_ collectionView: NSCollectionView, _ indexPath: IndexPath) -> (NSView & NSCollectionViewElement)   {
            if isRegistered(collectionView) == false {
                self.register(for: collectionView)
            }
            
            let view = collectionView.makeSupplementaryView(ofKind: self.elementKind, withIdentifier: self.identifier, for: indexPath) as! SupplementaryView
            self.handler(view, elementKind, indexPath)
            return view
        }
        
        internal func isRegistered(_ collectionView: NSCollectionView) -> Bool {
            collectionView.registeredSupplementaryRegistrations.contains(self.identifier)
        }
        
        internal func register(for collectionView: NSCollectionView) {
            if let nib = self.nib {
                collectionView.register(nib, forSupplementaryViewOfKind: self.elementKind, withIdentifier: self.identifier)
            } else {
                collectionView.register(SupplementaryView.self, forSupplementaryViewOfKind: self.elementKind, withIdentifier: self.identifier)
            }
            collectionView.registeredSupplementaryRegistrations.append(self.identifier)
        }
        
        internal func unregister(for collectionView: NSCollectionView) {
            let any: AnyClass? = nil
            collectionView.register(any, forItemWithIdentifier: self.identifier)
            collectionView.registeredSupplementaryRegistrations.remove(self.identifier)
        }
    }
}

internal extension NSCollectionView {
    var registeredSupplementaryRegistrations: [NSUserInterfaceItemIdentifier] {
         get { getAssociatedValue(key: "_registeredSupplementaryRegistrations", object: self, initialValue: []) }
         set { set(associatedValue: newValue, key: "_registeredSupplementaryRegistrations", object: self)
         }
     }
}
