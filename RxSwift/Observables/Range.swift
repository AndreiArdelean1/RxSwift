//
//  Range.swift
//  RxSwift
//
//  Created by Krunoslav Zaher on 9/13/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

extension ObservableType where Element: RxAbstractInteger {
    /**
     Generates an observable sequence of integral numbers within a specified range, using the specified scheduler to generate and send out observer messages.

     - seealso: [range operator on reactivex.io](http://reactivex.io/documentation/operators/range.html)

     - parameter start: The value of the first integer in the sequence.
     - parameter count: The number of sequential integers to generate.
     - parameter scheduler: Scheduler to run the generator loop on.
     - returns: An observable sequence that contains a range of sequential integral numbers.
     */
    public static func range(start: Element, count: Element, scheduler: ImmediateSchedulerType = CurrentThreadScheduler.instance) -> Observable<Element> {
        RangeProducer<Element>(start: start, count: count, scheduler: scheduler)
    }
}

final private class RangeProducer<Element: RxAbstractInteger>: Producer<Element>, @unchecked Sendable {
    fileprivate let start: Element
    fileprivate let count: Element
    fileprivate let scheduler: ImmediateSchedulerType

    init(start: Element, count: Element, scheduler: ImmediateSchedulerType) {
        guard count >= 0 else {
            rxFatalError("count can't be negative")
        }

        guard start &+ (count - 1) >= start || count == 0 else {
            rxFatalError("overflow of count")
        }

        self.start = start
        self.count = count
        self.scheduler = scheduler
    }
    
    override func run<Observer: ObserverType>(_ observer: Observer, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where Observer.Element == Element {
        let sink = RangeSink(parent: self, observer: observer, cancel: cancel)
        let subscription = sink.run()
        return (sink: sink, subscription: subscription)
    }
}

final private class RangeSink<Observer: ObserverType>: Sink<Observer>, @unchecked Sendable where Observer.Element: RxAbstractInteger {
    typealias Parent = RangeProducer<Observer.Element>
    
    private let parent: Parent
    
    init(parent: Parent, observer: Observer, cancel: Cancelable) {
        self.parent = parent
        super.init(observer: observer, cancel: cancel)
    }
    
    func run() -> Disposable {
        return self.parent.scheduler.scheduleRecursive(0 as Observer.Element) { i, recurse in
            if i < self.parent.count {
                self.forwardOn(.next(self.parent.start + i))
                recurse(i + 1)
            }
            else {
                self.forwardOn(.completed)
                self.dispose()
            }
        }
    }
}
