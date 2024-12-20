//
//  ConcurrentMainScheduler.swift
//  RxSwift
//
//  Created by Krunoslav Zaher on 10/17/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

import Dispatch
import Foundation

/**
Abstracts work that needs to be performed on `MainThread`. In case `schedule` methods are called from main thread, it will perform action immediately without scheduling.

This scheduler is optimized for `subscribeOn` operator. If you want to observe observable sequence elements on main thread using `observeOn` operator,
`MainScheduler` is more suitable for that purpose.
*/
public final class ConcurrentMainScheduler : SchedulerType {
    public typealias TimeInterval = Foundation.TimeInterval
    public typealias Time = Date

    private let mainScheduler: MainScheduler
    private let mainQueue: DispatchQueue

    /// - returns: Current time.
    public var now: Date {
        self.mainScheduler.now as Date
    }

    private init(mainScheduler: MainScheduler) {
        self.mainQueue = DispatchQueue.main
        self.mainScheduler = mainScheduler
    }

    /// Singleton instance of `ConcurrentMainScheduler`
    public static let instance = ConcurrentMainScheduler(mainScheduler: MainScheduler.instance)

    /**
    Schedules an action to be executed immediately.

    - parameter state: State passed to the action to be executed.
    - parameter action: Action to be executed.
    - returns: The disposable object used to cancel the scheduled action (best effort).
    */
    public func schedule<StateType>(_ state: StateType, action: @escaping @Sendable (StateType) -> Disposable) -> Disposable {
        if DispatchQueue.isMain {
            return action(state)
        }

        let cancel = SingleAssignmentDisposable()

        self.mainQueue.async { @Sendable () in
            if cancel.isDisposed {
                return
            }

            cancel.setDisposable(action(state))
        }

        return cancel
    }

    /**
    Schedules an action to be executed.

    - parameter state: State passed to the action to be executed.
    - parameter dueTime: Relative time after which to execute the action.
    - parameter action: Action to be executed.
    - returns: The disposable object used to cancel the scheduled action (best effort).
    */
    public final func scheduleRelative<StateType>(_ state: StateType, dueTime: RxTimeInterval, action: @escaping @Sendable (StateType) -> Disposable) -> Disposable {
        self.mainScheduler.scheduleRelative(state, dueTime: dueTime, action: action)
    }

    /**
    Schedules a periodic piece of work.

    - parameter state: State passed to the action to be executed.
    - parameter startAfter: Period after which initial work should be run.
    - parameter period: Period for running the work periodically.
    - parameter action: Action to be executed.
    - returns: The disposable object used to cancel the scheduled action (best effort).
    */
    public func schedulePeriodic<StateType>(_ state: StateType, startAfter: RxTimeInterval, period: RxTimeInterval, action: @escaping @Sendable (StateType) -> StateType) -> Disposable {
        self.mainScheduler.schedulePeriodic(state, startAfter: startAfter, period: period, action: action)
    }
}
