//
//  IQPullToRefresh+LoadMore.swift
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

public protocol MoreLoadable: class {

    func loadMoreTriggered(type: IQPullToRefresh.LoadMoreType,
                           loadingBegin: @escaping (_ success: Bool) -> Void,
                           loadingFinished: @escaping (_ success: Bool) -> Void)
}

public extension IQPullToRefresh {

    enum LoadMoreType {
        case manual
        case reachAtEnd
    }

    var isMoreLoading: Bool {
        loadMoreControl.refreshState == .refreshing
    }

    func loadMore() {
        triggerSafeLoadMore(type: .manual)
    }


    internal func beginLoadMoreAnimation() {

        guard !isMoreLoading else {
            return
        }

        var contentInset = scrollView.contentInset
        contentInset.bottom += loadMoreControl.refreshHeight

        loadMoreControl.refreshState = .refreshing

        UIView.animate(withDuration: 0.1, delay: 0, options: .beginFromCurrentState, animations: { [weak self] in
            self?.scrollView.contentInset = contentInset
        }, completion: nil)
    }

    internal func endLoadMoreAnimation() {

        guard isMoreLoading else {
            return
        }

        var contentInset = scrollView.contentInset
        contentInset.bottom -= loadMoreControl.refreshHeight

        UIView.animate(withDuration: 0.1, delay: 0, options: .beginFromCurrentState, animations: { [weak self] in
            self?.scrollView.contentInset = contentInset
        }, completion: nil)

        loadMoreControl.refreshState = .none
    }

    internal func triggerSafeLoadMore(type: LoadMoreType) {

        if enableLoadMore, (!isMoreLoading || type == .reachAtEnd), let moreLoader = moreLoader {

            moreLoader.loadMoreTriggered(type: type, loadingBegin: { [weak self] (success) in
                if success {
                    if self?.isMoreLoading == false {
                        self?.beginLoadMoreAnimation()
                    }
                } else {
                    self?.endLoadMoreAnimation()
                }
            }, loadingFinished: { [weak self] (success) in
                self?.endLoadMoreAnimation()
            })
        }
    }
}
