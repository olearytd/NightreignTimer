import XCTest
import SwiftData // Use SwiftData, not CoreData
@testable import NightreignTimer // Import your app module

final class NightreignTimerTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    // This is run before each test
    @MainActor
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // --- Create an IN-MEMORY container for testing ---
        // 1. Create a configuration that stores data in memory only.
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        
        // 2. Create the container with the Item model, using the in-memory configuration.
        do {
            modelContainer = try ModelContainer(for: Item.self, configurations: configuration)
            modelContext = modelContainer.mainContext
        } catch {
            fatalError("Failed to create in-memory container: \(error)")
        }
        // ---------------------------------------------------
    }

    // This is run after each test
    override func tearDownWithError() throws {
        modelContainer = nil
        modelContext = nil
        try super.tearDownWithError()
    }

    // An example test for your SwiftData Item model
    @MainActor
    func testAddItemAndFetch() throws {
        // GIVEN: The in-memory database is empty
        
        // WHEN: A new Item is created and inserted into the context
        let newItem = Item(timestamp: Date())
        modelContext.insert(newItem)
        
        // THEN: We should be able to fetch exactly one item
        
        // In SwiftData, we use a FetchDescriptor, not an NSFetchRequest
        let descriptor = FetchDescriptor<Item>()
        
        let fetchedItems = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(fetchedItems.count, 1, "There should be exactly one item in the database.")
        XCTAssertEqual(fetchedItems.first?.timestamp, newItem.timestamp, "The fetched item's timestamp should match the new item's.")
    }
}
