//
//  UIGestureRecognizer+Rx.swift
//  RxCocoa
//
//  Created by Carlos García on 10/6/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if os(iOS) || os(tvOS) || os(visionOS)

import UIKit
import RxSwift

// This should be only used from `MainScheduler`
@MainActor
final class GestureTarget<Recognizer: UIGestureRecognizer>: RxTarget, @unchecked Sendable {
    typealias Callback = @Sendable @MainActor (Recognizer) -> Void
    
    let selector = #selector(GestureTarget.eventHandler(_:))
    
    weak var gestureRecognizer: Recognizer?
    var callback: Callback?
    
    init(_ gestureRecognizer: Recognizer, callback: @escaping Callback) {
        self.gestureRecognizer = gestureRecognizer
        self.callback = callback
        
        super.init()
        
        gestureRecognizer.addTarget(self, action: selector)

        let method = self.method(for: selector)
        if method == nil {
            fatalError("Can't find method")
        }
    }
    
    @objc func eventHandler(_ sender: UIGestureRecognizer) {
        if let callback = self.callback, let gestureRecognizer = self.gestureRecognizer {
            callback(gestureRecognizer)
        }
    }
    
    override func dispose() {
        super.dispose()
        
        MainScheduler.assumeMainActor(execute: {
            self.gestureRecognizer?.removeTarget(self, action: self.selector)
            self.callback = nil
        })
    }
}

extension Reactive where Base: UIGestureRecognizer {
    
    /// Reactive wrapper for gesture recognizer events.
    public var event: ControlEvent<Base> {
        let source: Observable<Base> = Observable.create { [weak control = self.base] observer in
            MainScheduler.ensureRunningOnMainThread()

            guard let control = control else {
                observer.on(.completed)
                return Disposables.create()
            }
            
            let observer = MainScheduler.assumeMainActor(execute: {
                return GestureTarget(control) { control in
                    observer.on(.next(control))
                }
            })
            
            return observer
        }.take(until: deallocated)
        
        return ControlEvent(events: source)
    }
    
}

#endif
