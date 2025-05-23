# NSTableViewDiffableDataSource

Extensions for `NSTableViewDiffableDataSource`.

## Topics

### Creating a Diffable Data Source

- ``AppKit/NSTableViewDiffableDataSource/init(tableView:cellRegistration:)``
- ``AppKit/NSTableViewDiffableDataSource/init(tableView:cellRegistration:sectionHeaderRegistration:)``
- ``AppKit/NSTableViewDiffableDataSource/init(tableView:cellRegistrations:)``
- ``AppKit/NSTableViewDiffableDataSource/init(tableView:cellRegistrations:sectionHeaderRegistration:)``

### Creating Section Views

- ``AppKit/NSTableViewDiffableDataSource/applySectionHeaderViewRegistration(_:)``

### Updating data

- ``AppKit/NSTableViewDiffableDataSource/apply(_:_:completion:)``

### Supporting deleting

- ``AppKit/NSTableViewDiffableDataSource/deletingHandlers-swift.property``
- ``AppKit/NSTableViewDiffableDataSource/DeletingHandlers-swift.struct``

### Supporting protocol requirements

- ``AppKit/NSTableViewDiffableDataSource/tableView(_:isGroupRow:)``
- ``AppKit/NSTableViewDiffableDataSource/tableView(_:rowViewForRow:)``
- ``AppKit/NSTableViewDiffableDataSource/tableView(_:viewFor:row:)``
