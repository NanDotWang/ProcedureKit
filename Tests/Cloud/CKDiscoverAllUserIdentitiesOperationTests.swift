//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

#if !os(tvOS)

import XCTest
import CloudKit
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCloud

class TestCKDiscoverAllUserIdentitiesOperation: TestCKOperation, CKDiscoverAllUserIdentitiesOperationProtocol, AssociatedErrorProtocol {
    typealias AssociatedError = PKCKError

    var error: Error?
    var userIdentityDiscoveredBlock: ((UserIdentity) -> Void)? = nil
    var discoverAllUserIdentitiesCompletionBlock: ((Error?) -> Void)? = nil

    init(error: Error? = nil) {
        self.error = error
        super.init()
    }

    override func main() {
        discoverAllUserIdentitiesCompletionBlock?(error)
    }
}

class CKDiscoverAllUserIdentitiesOperationTests: CKProcedureTestCase {

    var target: TestCKDiscoverAllUserIdentitiesOperation!
    var operation: CKProcedure<TestCKDiscoverAllUserIdentitiesOperation>!

    override func setUp() {
        super.setUp()
        target = TestCKDiscoverAllUserIdentitiesOperation()
        operation = CKProcedure(operation: target)
    }

    func test__set_get__userIdentityDiscoveredBlock() {
        var setByCompletionBlock = false
        let block: (String) -> Void = { identity in
            setByCompletionBlock = true
        }
        operation.userIdentityDiscoveredBlock = block
        XCTAssertNotNil(operation.userIdentityDiscoveredBlock)
        target.userIdentityDiscoveredBlock?("hello@world.com")
        XCTAssertTrue(setByCompletionBlock)
    }

    func test__success_without_completion_block() {
        wait(for: operation)
        XCTAssertProcedureFinishedWithoutErrors(operation)
    }

    func test__success_with_completion_block() {
        var didExecuteBlock = false
        operation.setDiscoverAllUserIdentitiesCompletionBlock { didExecuteBlock = true }
        wait(for: operation)
        XCTAssertProcedureFinishedWithoutErrors(operation)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_without_completion_block() {
        target.error = TestError()
        wait(for: operation)
        XCTAssertProcedureFinishedWithoutErrors(operation)
    }

    func test__error_with_completion_block() {
        var didExecuteBlock = false
        operation.setDiscoverAllUserIdentitiesCompletionBlock { didExecuteBlock = true }
        target.error = TestError()
        wait(for: operation)
        XCTAssertProcedureFinishedWithErrors(operation, count: 1)
        XCTAssertFalse(didExecuteBlock)
    }
}

class CloudKitProcedureDiscoverAllUserIdentitiesOperationTests: CKProcedureTestCase {

    var setByUserIdentityDiscoveredBlock = false
    var cloudkit: CloudKitProcedure<TestCKDiscoverAllUserIdentitiesOperation>!

    override func setUp() {
        super.setUp()
        cloudkit = CloudKitProcedure(strategy: .immediate) { TestCKDiscoverAllUserIdentitiesOperation() }
        cloudkit.container = container
        cloudkit.userIdentityDiscoveredBlock = { [weak self] _ in
            self?.setByUserIdentityDiscoveredBlock = true
        }
    }

    func test__set_get_userIdentityDiscoveredBlock() {
        XCTAssertNotNil(cloudkit.userIdentityDiscoveredBlock)
        cloudkit.userIdentityDiscoveredBlock?("user identity")
        XCTAssertTrue(setByUserIdentityDiscoveredBlock)
    }

    func test__cancellation() {
        cloudkit.cancel()
        wait(for: cloudkit)
        XCTAssertProcedureCancelledWithoutErrors(cloudkit)
    }

    func test__success_without_completion_block_set() {
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
    }

    func test__success_with_completion_block_set() {
        var didExecuteBlock = false
        cloudkit.setDiscoverAllUserIdentitiesCompletionBlock {
            didExecuteBlock = true
        }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_without_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKDiscoverAllUserIdentitiesOperation()
            operation.error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            return operation
        }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
    }

    func test__error_with_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKDiscoverAllUserIdentitiesOperation()
            operation.error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            return operation
        }

        var didExecuteBlock = false
        cloudkit.setDiscoverAllUserIdentitiesCompletionBlock {
            didExecuteBlock = true
        }

        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithErrors(cloudkit, count: 1)
        XCTAssertFalse(didExecuteBlock)
    }
}

#endif
