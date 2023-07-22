# Advanced NSCollectionView & NSTableView

A collection of classes and extensions for NSCollectionView and NSTableView, many of them being ports of modern UIKit.

Take a look at the included example project which demonstrates `itemRegistration`, `cellRegistration`, `NSItemContentConfiguration`, `AdvanceColllectionViewDiffableDataSource` and reloading of items.

## ItemRegistration & CellRegistration
A port of `UICollectionView.CellRegistration`. A registration for collection view items and table cells that greatly simplifies  configurating them.
```
struct GalleryItem {
    let title: String
    let image: NSImage
}

let itemRegistration = NSCollectionView.ItemRegistration<NSCollectionViewItem, GalleryItem> { item, indexPath, galleryItem in

    item.textField.stringValue = galleryItem.title
    item.imageView.image = galleryItem.image
    
    // Gets called whenever the state of the item changes (e.g. on selection)
    item.configurationUpdateHandler = { item, state in
        // Updates the text color based on selection state.
        item.textField.textColor = state.isSelected ? .controlAccentColor : .labelColor
    }
}
```

## ContentConfiguration
A port of UIContentConfiguration that allows configurating NSCollectionView items and NSTableView cells via content configurations.

### NSHostingConfiguration
A content configuration suitable for hosting a hierarchy of SwiftUI views.
```
collectionViewItem.contentConfiguration = NSHostingConfiguration {
    HStack {
        Image(systemName: "star").foregroundStyle(.purple)
        Text("Favorites")
        Spacer()
    }
}
```
### NSTableCellContentConfiguration
A content configuration for a table cell.
 ```
 var content = tableCell.defaultContentConfiguration()

 // Configure content.
 content.image = NSImage(systemSymbolName: "star")
 content.text = "Favorites"

 // Customize appearance.
 content.imageProperties.tintColor = .purple

 tableCell.contentConfiguration = content
 ```
 
 ### NSItemContentconfiguration
A content configuration for a collectionview item.
 ```
 public var content = collectionViewItem.defaultContentConfiguration()

 // Configure content.
 content.text = "Favorites"
 content.image = NSImage(systemSymbolName: "star", accessibilityDescription: "star")

 // Customize appearance.
 content.imageProperties.tintColor = .purple

 collectionViewItem.contentConfiguration = content
 ```

## NSCollectionView reconfigurateItems
Updates the data for the items at the index paths you specify, preserving the existing cells for the items.
To update the contents of existing (including prefetched) cells without replacing them with new cells, use this method instead of `reloadItems(at:)`.
```
collectionView.reconfigurateItems(at: [IndexPath(item: 1, section: 1)])
```

## AdvanceColllectionViewDiffableDataSource
An extended `NSCollectionViewDiffableDataSource that provides:

 - Reordering of items by enabling `allowsReording`and optionally providing blocks to `reorderingHandlers`.
 - Deleting of items by enabling `allowsDeleting`and optionally providing blocks to `DeletionHandlers`.
 - Quicklooking of items via spacebar by providing elements conforming to `QuicklookPreviewable`.
 - Handlers for selection of items `selectionHandlers`.
 - Handlers for items that get hovered by mouse `hoverHandlers`.
 - Providing a right click menu for selected items via `menuProvider` block.
 - Handler for pinching of the collection view via `pinchHandler`.

## AdvanceTableViewDiffableDataSource
An extended `NSTableViewDiffableDataSource. **Currently not working.**
