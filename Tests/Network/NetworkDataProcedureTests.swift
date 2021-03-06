//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitNetwork

class NetworkDataProcedureTests: ProcedureKitTestCase {

    var url: URL!
    var request: URLRequest!
    var session: TestableURLSessionTaskFactory!
    var download: NetworkDataProcedure<TestableURLSessionTaskFactory>!

    override func setUp() {
        super.setUp()
        url = "http://procedure.kit.run"
        request = URLRequest(url: url)
        session = TestableURLSessionTaskFactory()
        download = NetworkDataProcedure(session: session, request: request)
    }

    func test__session_receives_request() {
        wait(for: download)
        XCTAssertProcedureFinishedWithoutErrors(download)
        XCTAssertEqual(session.didReceiveDataRequest?.url, url)
    }

    func test__session_creates_data_task() {
        wait(for: download)
        XCTAssertProcedureFinishedWithoutErrors(download)
        XCTAssertNotNil(session.didReturnDataTask)
        XCTAssertEqual(session.didReturnDataTask, download.task)
    }

    func test__download_resumes_data_task() {
        wait(for: download)
        XCTAssertProcedureFinishedWithoutErrors(download)
        XCTAssertTrue(session.didReturnDataTask?.didResume ?? false)
    }

    func test__download_cancels_data_task_is_cancelled() {
        session.delay = 2.0
        let delay = DelayProcedure(by: 0.1)
        delay.addDidFinishBlockObserver { _ in
            self.download.cancel()
        }
        wait(for: download, delay)
        XCTAssertProcedureCancelledWithoutErrors(download)
        XCTAssertTrue(session.didReturnDataTask?.didCancel ?? false)
    }

    func test__no_requirement__finishes_with_error() {
        download = NetworkDataProcedure(session: session) { _ in }
        wait(for: download)
        XCTAssertProcedureFinishedWithErrors(download, count: 1)
        XCTAssertEqual(download.errors.first as? ProcedureKitError, ProcedureKitError.requirementNotSatisfied())
    }

    func test__no_data__finishes_with_error() {
        session.returnedData = nil
        wait(for: download)
        XCTAssertProcedureFinishedWithErrors(download, count: 1)
    }

    func test__session_error__finishes_with_error() {
        session.returnedError = TestError()
        wait(for: download)
        XCTAssertProcedureFinishedWithErrors(download, count: 1)
        XCTAssertEqual(download.errors.first as? TestError, session.returnedError as? TestError)
    }

    func test__completion_handler_receives_data_and_response() {
        var completionHandlerDidExecute = false
        download = NetworkDataProcedure(session: session, request: request) { result in            
            XCTAssertEqual(result.payload, self.session.returnedData)
            XCTAssertEqual(result.response, self.session.returnedResponse)
            completionHandlerDidExecute = true
        }
        wait(for: download)
        XCTAssertProcedureFinishedWithoutErrors(download)
        XCTAssertTrue(completionHandlerDidExecute)
    }
}
