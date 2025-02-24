//
//  ChildTracker.swift
//  Mlem
//
//  Created by Eric Andrews on 2023-10-16.
//
import Foundation

class ChildTracker<Item: TrackerItem, ParentItem: TrackerItem>: StandardTracker<Item>, ChildTrackerProtocol {
    private weak var parentTracker: (any ParentTrackerProtocol)?
    private var streamCursor: Int = 0
    
    private(set) var sortType: TrackerSortType
    
    var allItems: [ParentItem] { items.map { toParent(item: $0) }}
    
    init(internetSpeed: InternetSpeed, sortType: TrackerSortType) {
        self.sortType = sortType
        super.init(internetSpeed: internetSpeed)
    }

    func toParent(item: Item) -> ParentItem {
        preconditionFailure("This method must be implemented by the inheriting class")
    }
    
    func setParentTracker(_ newParent: any ParentTrackerProtocol) {
        parentTracker = newParent
    }
    
    /// Gets the next item in the feed stream and increments the cursor
    /// - Returns: next item in the feed stream
    /// - Warning: This is NOT a thread-safe function! Only one thread at a time may call this function!
    func consumeNextItem() -> ParentItem? {
        assert(
            streamCursor < items.count,
            "consumeNextItem called on a tracker without a next item (cursor: \(streamCursor), count: \(items.count))!"
        )

        if streamCursor < items.count {
            streamCursor += 1
            return toParent(item: items[streamCursor - 1])
        }

        return nil
    }

    /// Gets the sort value of the next item in feed stream for a given sort type without affecting the cursor. The sort type must match the sort type of this tracker.
    /// - Parameter sortType: type of sorting being performed
    /// - Returns: sorting value of the next tracker item corresponding to the given sort type
    /// - Warning: This is NOT a thread-safe function! Only one thread at a time may call this function!
    func nextItemSortVal(sortType: TrackerSortType) async throws -> TrackerSortVal? {
        assert(sortType == self.sortType, "Conflicting types for sortType! This will lead to unexpected sorting behavior.")

        if streamCursor < items.count {
            return items[streamCursor].sortVal(sortType: sortType)
        } else {
            // if done loading, return nil
            if loadingState == .done {
                return nil
            }

            // otherwise, wait for the next page to load and try to return the first value
            // if the next page is already loading, this call to loadNextPage will be noop, but still wait until that load completes thanks to the semaphore
            await loadMoreItems()
            return streamCursor < items.count ? items[streamCursor].sortVal(sortType: sortType) : nil
        }
    }
    
    /// Resets the cursor to 0 but does not unload any items
    func resetCursor() {
        streamCursor = 0
    }

    func refresh(clearBeforeRefresh: Bool, notifyParent: Bool = true) async throws {
        try await refresh(clearBeforeRefresh: clearBeforeRefresh)
        streamCursor = 0

        if notifyParent, let parentTracker {
            await parentTracker.refresh(clearBeforeFetch: clearBeforeRefresh)
        }
    }

    func reset(notifyParent: Bool = true) async {
        await clear()
        streamCursor = 0
        if notifyParent, let parentTracker {
            await parentTracker.reset()
        }
    }
    
    @discardableResult override func filter(with filter: @escaping (Item) -> Bool) async -> Int {
        let newItems = items.filter(filter)
        let removed = items.count - newItems.count
        
        streamCursor = 0
        await setItems(newItems)
        
        return removed
    }
    
    /// Filters items from the parent tracker according to the given filtering criterion
    /// - Parameter filter: function that, given a TrackerItem, returns true if the item should REMAIN in the tracker
    func filterFromParent(with filter: @escaping (any TrackerItem) -> Bool) async {
        await parentTracker?.filter(with: filter)
    }
}
