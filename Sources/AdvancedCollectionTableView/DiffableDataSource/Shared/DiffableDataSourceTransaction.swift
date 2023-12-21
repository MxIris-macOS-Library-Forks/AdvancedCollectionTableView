//
//  DiffableDataSourceTransaction.swift
//
//
//  Created by Florian Zand on 16.09.23.
//

import AppKit

/// A transaction that describes the changes after reordering the items in the view.
public struct DiffableDataSourceTransaction<Section, Element> where Section: Hashable, Element: Hashable {
    /// The snapshot before the transaction occured.
    let initialSnapshot: NSDiffableDataSourceSnapshot<Section, Element>
    
    /// The snapshot after the transaction occured.
    let finalSnapshot: NSDiffableDataSourceSnapshot<Section, Element>
    
    /// A collection of insertions and removals that describe the difference between initial and final snapshots.
    let difference: CollectionDifference<Element>
}