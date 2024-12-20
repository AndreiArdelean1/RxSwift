//
//  ToArray.swift
//  RxSwift
//
//  Created by Junior B. on 20/10/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

extension ObservableType {
    /**
    Converts an Observable into a Single that emits the whole sequence as a single array and then terminates.
    
    For aggregation behavior see `reduce`.

    - seealso: [toArray operator on reactivex.io](http://reactivex.io/documentation/operators/to.html)
    
    - returns: A Single sequence containing all the emitted elements as array.
    */
    public func toArray()
        -> Single<[Element]> {
        PrimitiveSequence(raw: ToArray(source: self.asObservable()))
    }
}

final private class ToArraySink<SourceType, Observer: ObserverType>: Sink<Observer>, ObserverType, @unchecked Sendable where Observer.Element == [SourceType] {
    typealias Parent = ToArray<SourceType>
    
    let parent: Parent
    var list = [SourceType]()
    
    init(parent: Parent, observer: Observer, cancel: Cancelable) {
        self.parent = parent
        
        super.init(observer: observer, cancel: cancel)
    }
    
    func on(_ event: Event<SourceType>) {
        switch event {
        case .next(let value):
            self.list.append(value)
        case .error(let e):
            self.forwardOn(.error(e))
            self.dispose()
        case .completed:
            self.forwardOn(.next(self.list))
            self.forwardOn(.completed)
            self.dispose()
        }
    }
}

final private class ToArray<SourceType>: Producer<[SourceType]>, @unchecked Sendable {
    let source: Observable<SourceType>

    init(source: Observable<SourceType>) {
        self.source = source
    }
    
    override func run<Observer: ObserverType>(_ observer: Observer, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where Observer.Element == [SourceType] {
        let sink = ToArraySink(parent: self, observer: observer, cancel: cancel)
        let subscription = self.source.subscribe(sink)
        return (sink: sink, subscription: subscription)
    }
}
