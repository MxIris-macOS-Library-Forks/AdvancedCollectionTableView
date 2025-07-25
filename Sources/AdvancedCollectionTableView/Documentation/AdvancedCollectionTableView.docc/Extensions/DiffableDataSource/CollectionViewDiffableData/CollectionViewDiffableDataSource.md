# ``CollectionViewDiffableDataSource``

## Topics

### Creating a diffable data source

- ``init(collectionView:itemProvider:)``
- ``init(collectionView:itemRegistration:)``
- ``ItemProvider``

### Creating supplementary views

- ``supplementaryViewProvider-swift.property``
- ``SupplementaryViewProvider-swift.typealias``
- ``useSupplementaryRegistrations(_:)``

### Identifying elements

- ``elements``
- ``selectedElements``
- ``displayingElements``
- ``element(for:)``
- ``element(at:)``
- ``elements(for:)``
- ``indexPath(for:)``
- ``reloadElements(_:animated:)``
- ``reconfigureElements(_:)``
- ``selectElements(_:byExtendingSelection:scrollPosition:)`` 
- ``selectElements(in:scrollPosition:)``
- ``deselectElements(_:)``
- ``deselectElements(in:)``
- ``scrollToElements(_:scrollPosition:)``

### Identifying sections

- ``sections``
- ``section(at:)``
- ``index(for:)``
- ``scrollToSection(_:scrollPosition:)``

### Updating data

- ``snapshot()``
- ``emptySnapshot()``
- ``apply(_:_:completion:)``

### Configurating user interaction

- ``menuProvider``
- ``doubleClickHandler``
- ``rightClickHandler``

### Displaying empty view

- ``emptyView``
- ``emptyContentConfiguration``
- ``emptyHandler``

### Previewing elements

- ``isQuicklookPreviewable``
- ``quicklookElements(_:current:)``
- ``previewImage(for:)``
- ``previewImage(for:size:)``
- ``previewImage(for:width:)``
- ``previewImage(for:height:)``

### Supporting prefetching elements

- ``prefetchHandlers-swift.property``
- ``PrefetchHandlers-swift.struct``

### Supporting reordering elements

- ``reorderingHandlers-swift.property``
- ``ReorderingHandlers-swift.struct``

### Supporting deleting elements

- ``deletingHandlers-swift.property``
- ``DeletingHandlers-swift.struct``

### Handling selecting elements

- ``selectionHandlers-swift.property``
- ``SelectionHandlers-swift.struct``

### Handling displaying elements

- ``displayHandlers-swift.property``
- ``DisplayHandlers-swift.struct``

### Handling hovering elements

- ``hoverHandlers-swift.property``
- ``HoverHandlers-swift.struct``

### Handling highlighting elements

- ``highlightHandlers-swift.property``
- ``HighlightHandlers-swift.struct``

### Managing drag interactions

- ``draggingHandlers-swift.property``
- ``DraggingHandlers-swift.struct``

### Managing drop interactions

- ``droppingHandlers-swift.property``
- ``DroppingHandlers-swift.struct``

### Supporting protocol requirements

- <doc:CollectionViewDiffableDataSource-Protocol-Implementations>
