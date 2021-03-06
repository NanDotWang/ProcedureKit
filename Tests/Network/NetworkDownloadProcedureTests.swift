//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//
import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitNetwork

class NetworkDownloadProcedureTests: ProcedureKitTestCase {

    var url: URL!
    var request: URLRequest!
    var session: TestableURLSessionTaskFactory!
    var download: NetworkDownloadProcedure<TestableURLSessionTaskFactory>!

    override func setUp() {
        super.setUp()
        url = "http://procedure.kit.run"
        request = URLRequest(url: url)
        session = TestableURLSessionTaskFactory()
        download = NetworkDownloadProcedure(session: session, request: request)
    }

    func test__session_receive_request() {
        wait(for: download)
        XCTAssertProcedureFinishedWithoutErrors(download)
        XCTAssertEqual(session.didReceiveDownloadRequest?.url, url)
    }

    func test__session_creates_download_task() {
        wait(for: download)
        XCTAssertProcedureFinishedWithoutErrors(download)
        XCTAssertNotNil(session.didReturnDownloadTask)
        XCTAssertEqual(session.didReturnDownloadTask, download.task)
    }

    func test__download_resumes_download_task() {
        wait(for: download)
        XCTAssertProcedureFinishedWithoutErrors(download)
        XCTAssertTrue(session.didReturnDownloadTask?.didResume ?? false)
    }

    func test__download_cancels_data_download_is_cancelled() {
        session.delay = 2.0
        let delay = DelayProcedure(by: 0.1)
        delay.addDidFinishBlockObserver { _ in
            self.download.cancel()
        }
        wait(for: download, delay)
        XCTAssertProcedureCancelledWithoutErrors(download)
        XCTAssertTrue(session.didReturnDownloadTask?.didCancel ?? false)
    }

    func test__no_requirement__finishes_with_error() {
        download = NetworkDownloadProcedure(session: session) { _ in }
        wait(for: download)
        XCTAssertProcedureFinishedWithErrors(download, count: 1)
        XCTAssertEqual(download.errors.first as? ProcedureKitError, ProcedureKitError.requirementNotSatisfied())
    }

    func test__no_data__finishes_with_error() {
        session.returnedURL = nil
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
        download = NetworkDownloadProcedure(session: session, request: request) { result in
            XCTAssertEqual(result.payload, self.session.returnedURL)
            XCTAssertEqual(result.response, self.session.returnedResponse)
            completionHandlerDidExecute = true
        }
        wait(for: download)
        XCTAssertProcedureFinishedWithoutErrors(download)
        XCTAssertTrue(completionHandlerDidExecute)
    }


}
