//
//  NSDiffableDataSourceSnapshot+ApplyOption.swift
//
//
//  Created by Florian Zand on 23.07.23.
//

import AppKit

/**
 Options for applying a snapshot to a diffable data source.

 Apple's `apply(_:animatingDifferences:completion:)` provides two options for applying snapshots to a diffable data source depending on `animatingDifferences`:
 - `true` applies a diff of the old and new state and applies the updates to the receiver animated.
 - `false`  is equivalent to calling `reloadData()`. It reloads every item/cell of the receiver.

 **Non-animated diff**

 `NSDiffableDataSourceSnapshotApplyOption`  lets you perform a diff even without animations using `withoutAnimation` for much better performance compared to using Apple's `reloadData()`.

 ```swift
 diffableDatasource.apply(snapshot, .withoutAnimation)
 ```

 **Animation duration**

 When you want to apply the snapshot animated, you can also change the animation duration  using `animated(duration:)`.

 ```swift
 diffableDatasource.apply(snapshot, .animated(duration: 1.0))
 ```
 */
public enum NSDiffableDataSourceSnapshotApplyOption: Hashable, Sendable {
    /**
     The snapshot gets applied animated.

     The data source computes a diff of the previous and new state and applies the updates to the receiver animated with a default animation duration.
     */
    public static var animated: Self { .animated(duration: noAnimationDuration) }

    /**
     The snapshot gets applied animiated with the specified animation duration.

     The data source computes a diff of the previous and new state and applies the updates to the receiver animated with the specified animation duration.
     */
    case animated(duration: TimeInterval)

    /**
     The snapshot gets applied using `reloadData()`.

     The system resets the UI to reflect the state of the data in the snapshot without computing a diff or animating the changes.
     */
    case usingReloadData
    /**
     The snapshot gets applied without any animation.

     The data source computes a diff of the previous and new state and applies the updates to the receiver without any animation.
     */
    case withoutAnimation

    static var noAnimationDuration: TimeInterval { 2_344_235 }

    var animationDuration: TimeInterval? {
        switch self {
        case let .animated(duration):
            guard duration != Self.noAnimationDuration else { return nil }
            guard let currentEvent = NSApplication.shared.currentEvent else { return duration }
            let flags = currentEvent.modifierFlags.intersection([.shift, .option, .control, .command])
            return duration * (flags == .shift ? 10 : 1)
        default:
            return nil
        }
    }
    
    var isReloadData: Bool {
        switch self {
        case .usingReloadData: return true
        default: return false
        }
    }
    
    var isWithoutAbinatuib: Bool {
        switch self {
        case .withoutAnimation: return true
        default: return false
        }
    }
}
