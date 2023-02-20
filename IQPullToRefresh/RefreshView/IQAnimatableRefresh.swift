//
//  IQAnimatableRefresh.swift
//  https://github.com/hackiftekhar/IQPullToRefresh
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import UIKit

public enum IQAnimatableRefreshState: Equatable {
    case unknown            // Unknown state for initialization
    case none               // refreshControler is not active
    case pulling(CGFloat)   // Pulling the refreshControl
    case eligible           // Progress is completed but touch not released
    case refreshing         // Triggered refreshing
}

public enum IQRefreshTriggerMode {

    case userInteraction    // Trigger when user manually pull (load more)

    case scrollLimitReached // Trigger when the scrollView reach at the end (load more)
}

public enum IQRefreshTriggerStyle: Equatable {

    case touchRelease   // Trigger when user pull 100% and then release touch

    case progressCompletion // Trigger when user pull 100%
}

public protocol IQAnimatableRefresh where Self: UIView {

    // Default is userInteraction
    var mode: IQRefreshTriggerMode { get set }

    // Default is touchRelease
    var refreshStyle: IQRefreshTriggerStyle { get set }

    // Default is 0
    var preloadOffset: CGFloat { get set }

    // Height of the refreshControl
    var refreshHeight: CGFloat { get }

    // Changes of the refreshControl state
    // You must implement didSet and do your UI updates based on the state
    var refreshState: IQAnimatableRefreshState { get set }
}

private var kRefreshMode = "kRefreshMode"
private var kRefreshStyle = "kRefreshStyle"
private var kPreloadOffset = "kPreloadOffset"

extension IQAnimatableRefresh {

    public var mode: IQRefreshTriggerMode {
        get {
            return objc_getAssociatedObject(self, &kRefreshMode) as? IQRefreshTriggerMode ?? .userInteraction
        }
        set {
            objc_setAssociatedObject(self, &kRefreshMode, newValue,
                                     objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    public var refreshStyle: IQRefreshTriggerStyle {
        get {
            return objc_getAssociatedObject(self, &kRefreshStyle) as? IQRefreshTriggerStyle ?? .touchRelease
        }
        set {
            objc_setAssociatedObject(self, &kRefreshStyle, newValue,
                                     objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    public var preloadOffset: CGFloat {
        get {
            return objc_getAssociatedObject(self, &kPreloadOffset) as? CGFloat ?? 0
        }
        set {
            objc_setAssociatedObject(self, &kPreloadOffset, newValue,
                                     objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
