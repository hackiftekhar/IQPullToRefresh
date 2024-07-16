//
//  IQPullToRefresh+Refresh.swift
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

@MainActor
public protocol Refreshable: AnyObject {

    @MainActor
    func refreshTriggered(type: IQPullToRefresh.RefreshType,
                          loadingBegin: @Sendable @escaping @MainActor (_ success: Bool) -> Void,
                          loadingFinished: @Sendable @escaping @MainActor (_ success: Bool) -> Void)
}

@MainActor
public extension IQPullToRefresh {

    enum RefreshType: Sendable {
       case manual
       case refreshControl
   }

    var isRefreshing: Bool {
        refreshControl.refreshState == .refreshing
    }

    func refresh() {
        triggerSafeRefresh(type: .manual)
    }

    func stopRefresh() {
        endPullToRefreshAnimation()
    }

    internal func beginPullToRefreshAnimation() {

        guard !isRefreshing else {
            return
        }

        if let refreshControl: UIRefreshControl = refreshControl as? UIRefreshControl {
            refreshControl.refreshState = .refreshing
        } else {
            var contentInset: UIEdgeInsets = scrollView.contentInset
            if scrollDirection == .horizontal {
                contentInset.left += refreshControl.refreshLength
            } else {
                contentInset.top += refreshControl.refreshLength
            }

            refreshControl.refreshState = .refreshing

            UIView.animate(withDuration: 0.1, delay: 0, options: .beginFromCurrentState, animations: { [weak self] in
                self?.scrollView.contentInset = contentInset
                self?.scrollView.layoutIfNeeded()
            }, completion: nil)
        }
    }

    internal func endPullToRefreshAnimation() {

        guard isRefreshing else {
            return
        }

        if let refreshControl: UIRefreshControl = refreshControl as? UIRefreshControl {
            refreshControl.refreshState = .none
        } else {
            var contentInset: UIEdgeInsets = scrollView.contentInset
            if scrollDirection == .horizontal {
                contentInset.left -= refreshControl.refreshLength
            } else {
                contentInset.top -= refreshControl.refreshLength
            }

            UIView.animate(withDuration: 0.1, delay: 0, options: .beginFromCurrentState, animations: { [weak self] in
                self?.scrollView.contentInset = contentInset
                self?.scrollView.layoutIfNeeded()
            }, completion: nil)

            refreshControl.refreshState = .none
        }
    }

    internal func triggerSafeRefresh(type: RefreshType) {

        if enablePullToRefresh, !isRefreshing || type == .refreshControl, let refresher = refresher {
            refresher.refreshTriggered(type: type, loadingBegin: { [weak self] (success) in
                if success {
                    if self?.isRefreshing == false {
                        self?.beginPullToRefreshAnimation()
                    }
                } else {
                    self?.endPullToRefreshAnimation()
                }
            }, loadingFinished: { [weak self] _ in
                self?.endPullToRefreshAnimation()
            })
        }
    }

    @objc internal func refreshControlDidRefresh() {
        triggerSafeRefresh(type: .refreshControl)
    }
}
