//
//  IQPullToRefresh.swift
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

public class IQPullToRefresh: NSObject {

    // MARK:- Public properties

    public private(set) var scrollView: UIScrollView

    public weak var refresher: Refreshable?
    public weak var moreLoader: MoreLoadable?

    public var enablePullToRefresh = false {
        didSet {

            assert(refresher != nil, "Cannot change `enablePullToRefresh`. Refresher is not specified.")

            guard oldValue != enablePullToRefresh else {
                return
            }

            if enablePullToRefresh {

                if let refreshControl = refreshControl as? UIRefreshControl {
                    scrollView.refreshControl = refreshControl
                } else {
                    scrollView.insertSubview(refreshControl, at: 0)
                    refreshControl.translatesAutoresizingMaskIntoConstraints = false
                    refreshControl.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
                    refreshControl.centerYAnchor.constraint(equalTo: scrollView.safeAreaLayoutGuide.topAnchor, constant: refreshControl.refreshHeight/2).isActive = true

                    if !isRefreshing {
                        refreshControl.refreshState = .none
                    }
                }
            } else {
                endPullToRefreshAnimation()
                if refreshControl is UIRefreshControl {
                    scrollView.refreshControl = nil
                } else {
                    refreshControl.removeFromSuperview()
                }
            }
        }
    }

    public var loadMoreControl: IQAnimatableRefresh {
        didSet {
            guard enableLoadMore else {
                return
            }

            oldValue.removeFromSuperview()
            scrollView.insertSubview(loadMoreControl, at: 0)
            loadMoreControl.translatesAutoresizingMaskIntoConstraints = false
            loadMoreControl.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
            loadMoreControl.centerYAnchor.constraint(equalTo: scrollView.safeAreaLayoutGuide.bottomAnchor, constant: -loadMoreControl.refreshHeight/2).isActive = true

            if !isMoreLoading {
                loadMoreControl.refreshState = .none
            }
        }
    }
    
    public var enableLoadMore = false {
        didSet {

            assert(moreLoader != nil, "Cannot change `enableLoadMore`. More Loader is not specified.")

            guard oldValue != enableLoadMore else {
                return
            }

            if enableLoadMore {
                scrollView.insertSubview(loadMoreControl, at: 0)
                loadMoreControl.translatesAutoresizingMaskIntoConstraints = false
                loadMoreControl.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
                loadMoreControl.centerYAnchor.constraint(equalTo: scrollView.safeAreaLayoutGuide.bottomAnchor, constant: -loadMoreControl.refreshHeight/2).isActive = true

                if !isMoreLoading {
                    loadMoreControl.refreshState = .none
                }
            } else {
                endLoadMoreAnimation()
                loadMoreControl.removeFromSuperview()
            }
        }
    }

    public var refreshControl: IQAnimatableRefresh {
        didSet {
            guard enablePullToRefresh else {
                return
            }

            oldValue.removeFromSuperview()
            if let refreshControl = refreshControl as? UIRefreshControl {
                scrollView.refreshControl = refreshControl
            } else {
                if oldValue is UIRefreshControl {
                    scrollView.refreshControl = nil
                }

                scrollView.insertSubview(refreshControl, at: 0)
                refreshControl.translatesAutoresizingMaskIntoConstraints = false
                refreshControl.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
                refreshControl.centerYAnchor.constraint(equalTo: scrollView.safeAreaLayoutGuide.topAnchor, constant: refreshControl.refreshHeight/2).isActive = true

                if !isRefreshing {
                    refreshControl.refreshState = .none
                }
            }
        }
    }


    // MARK:- Private properties
    internal static var contentOffsetObserverContext = 0

//    //In some cases, the loaders
//    private let refresherMask = CALayer()
//    private let moreLoaderMask = CALayer()

    // MARK:- Public functions

    deinit {
        scrollView.removeObserver(self, forKeyPath: #keyPath(UIScrollView.contentOffset), context: &Self.contentOffsetObserverContext)
    }

    public init(scrollView: UIScrollView,
                refresher: Refreshable? = nil,
                moreLoader: MoreLoadable? = nil) {


        self.scrollView = scrollView
        self.refresher = refresher
        self.moreLoader = moreLoader


        let refreshControl = UIRefreshControl()
        self.refreshControl = refreshControl

        let indicatorView: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            indicatorView = UIActivityIndicatorView(style: .large)
        } else {
            indicatorView = UIActivityIndicatorView(style: .whiteLarge)
            indicatorView.color = UIColor.darkGray
        }
        indicatorView.hidesWhenStopped = false
        self.loadMoreControl = indicatorView
        self.loadMoreControl.refreshState = .none

        super.init()

        refreshControl.addTarget(self, action: #selector(self.refreshControlDidRefresh), for: .valueChanged)
        scrollView.addObserver(self, forKeyPath: #keyPath(UIScrollView.contentOffset), options: [.old, .new], context: &Self.contentOffsetObserverContext)
    }
}

extension IQPullToRefresh {
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {

        if keyPath == #keyPath(UIScrollView.contentOffset) {

            let newOffset = scrollView.contentOffset
            let oldOffset = change?[.oldKey] as? CGPoint ?? newOffset

            // Pull to refresh
            if enablePullToRefresh, refresher != nil, !(refreshControl is UIRefreshControl), refreshControl.superview != nil, !isRefreshing {
                let topEdge = newOffset.y + scrollView.adjustedContentInset.top
                let edgeToPullToRefresh = -refreshControl.refreshHeight

                let estimatedProgress = topEdge / edgeToPullToRefresh
                let progress = max(0, min(1,estimatedProgress))

                if scrollView.isDragging == true {

                    if topEdge >= (edgeToPullToRefresh - refreshControl.refreshHeight) {
                        if progress >= 1 {
                            if refreshControl.refreshState != .eligible {
                                refreshControl.refreshState = .pulling(progress)
                                refreshControl.refreshState = .eligible
                            }
                        } else if progress <= 0 {
                            refreshControl.refreshState = .none
                        } else {
                            refreshControl.refreshState = .pulling(progress)
                        }
                    } else {
                        refreshControl.refreshState = .none
                    }
                } else if scrollView.isDecelerating {

                    if topEdge <= edgeToPullToRefresh {
                        beginPullToRefreshAnimation()
                        triggerSafeRefresh(type: .refreshControl)
                    } else {
                        if progress == 0 {
                            refreshControl.refreshState = .none
                        } else {
                            refreshControl.refreshState = .none
//                            refreshControl.refreshState = .pulling(progress)
                        }
                    }
                } else if refreshControl.refreshState != .refreshing {
                    refreshControl.refreshState = .none
                }
            }

            // Load more
            if enableLoadMore, moreLoader != nil, loadMoreControl.superview != nil, !isMoreLoading {

                let bottomEdge = newOffset.y + scrollView.frame.height
                let edgeToLoadMore = scrollView.contentSize.height + loadMoreControl.refreshHeight
                let estimatedProgress = (bottomEdge - (edgeToLoadMore - loadMoreControl.refreshHeight)) / loadMoreControl.refreshHeight

                let progress = max(0, min(1,estimatedProgress))

                if scrollView.isDragging == true {

                    if bottomEdge >= (edgeToLoadMore - loadMoreControl.refreshHeight) {
                        if progress >= 1 {
                            if loadMoreControl.refreshState != .eligible {
                                loadMoreControl.refreshState = .pulling(progress)
                                loadMoreControl.refreshState = .eligible
                            }
                        } else if progress <= 0 {
                            loadMoreControl.refreshState = .none
                        } else {
                            loadMoreControl.refreshState = .pulling(progress)
                        }
                    } else {
                        loadMoreControl.refreshState = .none
                    }
                } else if scrollView.isDecelerating {
                    if bottomEdge >= edgeToLoadMore {
                        beginLoadMoreAnimation()
                        triggerSafeLoadMore(type: .reachAtEnd)
                    } else {
                        if progress == 0 {
                            loadMoreControl.refreshState = .none
                        } else {
                            loadMoreControl.refreshState = .none
//                            loadMoreControl.refreshState = .pulling(progress)
                        }
                    }
                } else if loadMoreControl.refreshState != .refreshing {
                    loadMoreControl.refreshState = .none
                }
            }
        }
    }
}
