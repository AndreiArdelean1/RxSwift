//
//  UIActivityIndicatorView+Rx.swift
//  RxCocoa
//
//  Created by Ivan Persidskiy on 02/12/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if os(iOS) || os(tvOS) || os(visionOS)

import UIKit
import RxSwift

extension Reactive where Base: UIActivityIndicatorView {
    /// Bindable sink for `startAnimating()`, `stopAnimating()` methods.
    public var isAnimating: Binder<Bool> {
        MainScheduler.assumeMainActor(execute: {
            Binder(self.base) { activityIndicator, active in
                MainScheduler.assumeMainActor(execute: {
                    if active {
                        activityIndicator.startAnimating()
                    } else {
                        activityIndicator.stopAnimating()
                    }
                })
            }
        })
    }
}

#endif
