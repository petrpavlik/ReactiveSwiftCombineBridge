
import Combine
import ReactiveSwift

struct ReactiveSwiftCombineBridge {
    var text = "Hello, World!"
}

@available(iOS 13.0, *)
public extension AnyPublisher {

    func asSignalProducer() -> SignalProducer<Output, Failure> {
        
        let reference = self.share()

        return SignalProducer { (signal, lifetime) in
            let cancellable = reference.handleEvents(receiveCancel: {
                signal.sendInterrupted()
            }).sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        signal.sendCompleted()
                    case .failure(let error):
                        signal.send(error: error)
                    }
                },
                receiveValue: { value in
                    signal.send(value: value)
                }
            )

            lifetime.observeEnded {
                cancellable.cancel()
            }
        }
    }
}

@available(iOS 13.0, *)
public extension Signal {
    func asPublisher() -> AnyPublisher<Value, Error> {

        let x = PassthroughSubject<Value, Error>()

        self.on(event: { (event) in
            switch event {
            case .value(let value):
                x.send(value)
            case .failed(let error):
                x.send(completion: .failure(error))
            case .completed:
                x.send(completion: .finished)
            case .interrupted:
                x.send(completion: .finished)
            }
        }).observeCompleted {
            //
        }

        return x.eraseToAnyPublisher()
    }
}

@available(iOS 13.0, *)
extension SignalProducer {
    func startAsFuture() -> Future<Value, Error> {
        Future { (promise) in
            self.take(first: 1).startWithResult { (result) in
                promise(result)
            }
        }
    }
}
