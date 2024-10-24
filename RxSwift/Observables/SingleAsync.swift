//
//  SingleAsync.swift
//  RxSwift
//
//  Created by Junior B. on 09/11/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

extension ObservableType {

    /**
     The single operator is similar to first, but throws a `RxError.noElements` or `RxError.moreThanOneElement`
     if the source Observable does not emit exactly one element before successfully completing.

     - seealso: [single operator on reactivex.io](http://reactivex.io/documentation/operators/first.html)

     - returns: An observable sequence that emits a single element or throws an exception if more (or none) of them are emitted.
     */
    public func single()
        -> Observable<Element> {
        SingleAsync(source: self.asObservable())
    }

    /**
     The single operator is similar to first, but throws a `RxError.NoElements` or `RxError.MoreThanOneElement`
     if the source Observable does not emit exactly one element before successfully completing.

     - seealso: [single operator on reactivex.io](http://reactivex.io/documentation/operators/first.html)

     - parameter predicate: A function to test each source element for a condition.
     - returns: An observable sequence that emits a single element or throws an exception if more (or none) of them are emitted.
     */
    public func single(_ predicate: @escaping @Sendable (Element) throws -> Bool)
        -> Observable<Element> {
        SingleAsync(source: self.asObservable(), predicate: predicate)
    }
}

private final class SingleAsyncSink<Observer: ObserverType> : Sink<Observer>, ObserverType, @unchecked Sendable {
    typealias Element = Observer.Element
    typealias Parent = SingleAsync<Element>
    
    private let parent: Parent
    private var seenValue: Bool = false
    
    init(parent: Parent, observer: Observer, cancel: Cancelable) {
        self.parent = parent
        super.init(observer: observer, cancel: cancel)
    }
    
    func on(_ event: Event<Element>) {
        switch event {
        case .next(let value):
            do {
                let forward = try self.parent.predicate?(value) ?? true
                if !forward {
                    return
                }
            }
            catch let error {
                self.forwardOn(.error(error as Swift.Error))
                self.dispose()
                return
            }

            if self.seenValue {
                self.forwardOn(.error(RxError.moreThanOneElement))
                self.dispose()
                return
            }

            self.seenValue = true
            self.forwardOn(.next(value))
        case .error:
            self.forwardOn(event)
            self.dispose()
        case .completed:
            if self.seenValue {
                self.forwardOn(.completed)
            } else {
                self.forwardOn(.error(RxError.noElements))
            }
            self.dispose()
        }
    }
}

final class SingleAsync<Element>: Producer<Element>, @unchecked Sendable {
    typealias Predicate = @Sendable (Element) throws -> Bool
    
    private let source: Observable<Element>
    fileprivate let predicate: Predicate?
    
    init(source: Observable<Element>, predicate: Predicate? = nil) {
        self.source = source
        self.predicate = predicate
    }
    
    override func run<Observer: ObserverType>(_ observer: Observer, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where Observer.Element == Element {
        let sink = SingleAsyncSink(parent: self, observer: observer, cancel: cancel)
        let subscription = self.source.subscribe(sink)
        return (sink: sink, subscription: subscription)
    }
}
