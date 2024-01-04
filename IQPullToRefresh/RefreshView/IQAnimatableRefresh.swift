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

public enum IQAnimatableRefreshState: Equatable, Sendable {
    case unknown            // Unknown state for initialization
    case none               // refreshController is not active
    case pulling(CGFloat)   // Pulling the refreshControl
    case eligible           // Progress is completed but touch not released
    case refreshing         // Triggered refreshing
}

@objc public enum IQRefreshTriggerMode: Int, Sendable {

    case userInteraction    // Trigger when user manually pull (load more)

    case scrollLimitReached // Trigger when the scrollView reach at the end (load more)
}

@objc public enum IQRefreshTriggerStyle: Int, Equatable, Sendable {

    case touchRelease   // Trigger when user pull 100% and then release touch

    case progressCompletion // Trigger when user pull 100%
}

@MainActor
public protocol IQAnimatableRefresh where Self: UIView {

    // Default is userInteraction
    @MainActor
    var mode: IQRefreshTriggerMode { get set }

    // Default is touchRelease
    @MainActor
    var refreshStyle: IQRefreshTriggerStyle { get set }

    // Default is 0
    @MainActor
    var preloadOffset: CGFloat { get set }

    // Height of the refreshControl
    @MainActor
    @available(*, deprecated, message: "use 'refreshLength' instead")
    var refreshHeight: CGFloat { get }

    @MainActor
    var refreshLength: CGFloat { get }

    // Changes of the refreshControl state
    // You must implement didSet and do your UI updates based on the state
    @MainActor
    var refreshState: IQAnimatableRefreshState { get set }
}

public extension IQAnimatableRefresh {
    var refreshHeight: CGFloat { refreshLength }
}

@MainActor
private struct AssociatedKeys {
    static var mode: Int = 0
    static var refreshStyle: Int = 0
    static var preloadOffset: Int = 0
}

@MainActor
extension IQAnimatableRefresh {

    public var mode: IQRefreshTriggerMode {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.mode) as? IQRefreshTriggerMode ?? .userInteraction
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.mode, newValue,
                                     objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    public var refreshStyle: IQRefreshTriggerStyle {
        get {
            if let value = objc_getAssociatedObject(self, &AssociatedKeys.refreshStyle) as? IQRefreshTriggerStyle {
                return value
            } else {
                return .touchRelease
            }
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.refreshStyle, newValue,
                                     objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    public var preloadOffset: CGFloat {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.preloadOffset) as? CGFloat ?? 0
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.preloadOffset, newValue,
                                     objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
