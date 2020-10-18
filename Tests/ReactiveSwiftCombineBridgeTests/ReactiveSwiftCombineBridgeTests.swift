import XCTest
@testable import ReactiveSwiftCombineBridge
import ReactiveSwift
import Combine

@available(iOS 13.0, *)
final class ReactiveSwiftCombineBridgeTests: XCTestCase {

    func testAsFuture() {
        let signalProducer: SignalProducer<Bool, Error> = SignalProducer { (signal, _) in
            signal.send(value: true)
        }

        let valueExpectation = expectation(description: "value")
        let completedExpectation = expectation(description: "completed")

        let subscription = signalProducer.startAsFuture().sink { (completion) in
            switch completion {
            case .finished:
                completedExpectation.fulfill()
            case .failure(_):
                break
            }
        } receiveValue: { (value) in
            XCTAssert(value)
            valueExpectation.fulfill()
        }

        wait(for: [valueExpectation, completedExpectation], timeout: 1)

        subscription.cancel()
    }

    func testAsSignal() {

        class Counter {

            @Published private(set) var count = 0

            func incerement() {
                count += 1
            }
        }

        let counter = Counter()

        let countIs1Expecation = expectation(description: "count is 1")
        let disposedExpectation = expectation(description: "disposed")

        let disposable = counter.$count.eraseToAnyPublisher().asSignal()
            .on(disposed: {
                disposedExpectation.fulfill()
            })
            .observeValues({ (count) in
                if count == 1 {
                    countIs1Expecation.fulfill()
                } else {
                    XCTFail()
                }
            })

        wait(for: [countIs1Expecation], timeout: 1)

        disposable?.dispose()

        wait(for: [disposedExpectation], timeout: 1)
    }

    func testAsSignalProducer() {

        class Counter {

            @Published private(set) var count = 0

            func incerement() {
                count += 1
            }
        }

        let counter = Counter()

        let countIs0Expecation = expectation(description: "count is 0")
        let countIs1Expecation = expectation(description: "count is 1")
        let disposedExpectation = expectation(description: "disposed")

        let disposable = counter.$count.eraseToAnyPublisher().asSignalProducer()
            .on(disposed: {
                disposedExpectation.fulfill()
            })
            .startWithValues { (count) in
                if count == 0 {
                    countIs0Expecation.fulfill()
                } else if count == 1 {
                    countIs1Expecation.fulfill()
                } else {
                    XCTFail()
                }
        }

        wait(for: [countIs0Expecation], timeout: 1)

        counter.incerement()

        wait(for: [countIs1Expecation], timeout: 1)

        disposable.dispose()

        wait(for: [disposedExpectation], timeout: 1)
    }

    static var allTests = [
        ("testExample", testAsFuture),
    ]
}
