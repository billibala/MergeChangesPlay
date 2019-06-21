//
//  MergeChangesPlayTests.swift
//  MergeChangesPlayTests
//
//  Created by Bill on 6/16/19.
//  Copyright © 2019 Bill. All rights reserved.
//

import XCTest
import CoreData
@testable import MergeChangesPlay

class MergeChangesPlayTests: XCTestCase {
    var container: NSPersistentContainer!

    override func setUp() {
        super.setUp()
        container = loadDataModel()
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    override func tearDown() {
        destroyPersistentContainer(container)
        super.tearDown()
    }

    func testExampleOfNoChangeNotification() {
        let backgroundContext = container.newBackgroundContext()

        let mainEvent = Event(context: container.viewContext)
        mainEvent.timestamp = Date()
        mainEvent.name  = "My Name in Main Queue"
        try! container.viewContext.save()

        let mainObjID = mainEvent.objectID

        dump(mainEvent)

        backgroundContext.performAndWait {
            let theEvent = backgroundContext.object(with: mainObjID) as! Event
            dump(theEvent.timestamp)
            theEvent.timestamp = Date()
            theEvent.name = "Changed running in bg context"

            try! backgroundContext.save()
        }

        print("after all changes: \(mainEvent.name!)")
    }

    func testExampleReceivingChangeNotification() {
        let backgroundContext = container.newBackgroundContext()

        let mainEvent = Event(context: container.viewContext)
        mainEvent.timestamp = Date()
        mainEvent.name  = "My Name in Main Queue"
        try! container.viewContext.save()

        let mainObjID = mainEvent.objectID

        dump(mainEvent)
        let barrier = expectation(description: "bg context wait")

        backgroundContext.perform {
            let theEvent = backgroundContext.object(with: mainObjID) as! Event
            dump(theEvent.timestamp)
            theEvent.timestamp = Date()
            theEvent.name = "Changed running in bg context"

            try! backgroundContext.save()
            barrier.fulfill()
        }

        waitForExpectations(timeout: 2)
        print("after all changes: \(mainEvent.name!)")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
