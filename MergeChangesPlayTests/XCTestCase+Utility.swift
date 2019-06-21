//
//  XCTestCase+Utility.swift
//  MergeChangesPlayTests
//
//  Created by Bill on 6/16/19.
//  Copyright © 2019 Bill. All rights reserved.
//

import Foundation
import XCTest
import CoreData
@testable import MergeChangesPlay

extension NSManagedObjectModel {
    static let basecampModel: NSManagedObjectModel = {
        let bundle = Bundle(for: MasterViewController.self)
        return NSManagedObjectModel(contentsOf: bundle.url(forResource: "MergeChangesPlay", withExtension: "momd")!)!
    }()
}

extension NSPersistentContainer {
    convenience init(storeLocation: URL?) {
        self.init(
            name: "UnitTestPersistentContainer",
            managedObjectModel: .basecampModel
        )
        if let storeLocation = storeLocation, let storeDescription = persistentStoreDescriptions.first {
            storeDescription.url = storeLocation.appendingPathComponent("TestCase.sqlite")
            // Uncomment to use Core Spotlight
            //            storeDescription.setOption(NSCoreDataCoreSpotlightDelegate(forStoreWith: storeDescription, model: managedObjectModel), forKey: NSCoreDataCoreSpotlightExporter)
        }
    }
}

extension XCTestCase {
    static func createTemporaryStoreDirectory() -> URL {
        let bundle = Bundle(for: MasterViewController.self)
        let parentFolder = try! FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: bundle.resourceURL, create: true)

        return parentFolder
    }

    func loadDataModel(enableHistoryTracking: Bool = false) -> NSPersistentContainer {
        let storeURL = XCTestCase.createTemporaryStoreDirectory()
        let container = NSPersistentContainer(storeLocation: storeURL)
        if enableHistoryTracking, let storeDescription = container.persistentStoreDescriptions.first {
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            storeDescription.setOption(true as NSNumber, forKey: "NSPersistentStoreRemoteChangeNotificationOptionKey")

        }
        container.loadPersistentStores { containerDescription, error in
            if let error = error {
                dump(error)
                fatalError()
            }
            if let storeURL = containerDescription.url {
                print("Unit test store location: \(storeURL.absoluteString)")
            }
        }
        return container
    }

    func destroyPersistentContainer(_ container: NSPersistentContainer) {
        // First, figure out the parent folder
        guard let parentDir = container.persistentStoreCoordinator.persistentStores.first?.url?.deletingLastPathComponent() else {
            return
        }
        // destroy the store
        container.viewContext.automaticallyMergesChangesFromParent = false
        container.persistentStoreCoordinator.persistentStores.forEach {
            try! container.persistentStoreCoordinator.destroyPersistentStore(at: $0.url!, ofType: $0.type, options: nil)
//            try! container.persistentStoreCoordinator.remove($0)
        }
        // trash the folder
        try! FileManager.default.removeItem(at: parentDir)
    }
}

