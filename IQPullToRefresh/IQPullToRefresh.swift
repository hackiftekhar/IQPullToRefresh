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

public final class IQPullToRefresh: NSObject {

    // MARK: - Public properties

    public private(set) var scrollView: UIScrollView

    public weak var refresher: Refreshable?
    public weak var moreLoader: MoreLoadable?

    private var contentOffsetObserver: NSKeyValueObservation?

    public var enablePullToRefresh: Bool = false {
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
                    refreshControl.centerYAnchor.constraint(equalTo: scrollView.safeAreaLayoutGuide.topAnchor,
                                                            constant: refreshControl.refreshHeight/2).isActive = true

                    if !isRefreshing {
                        refreshControl.setNeedsLayout()
                        refreshControl.layoutIfNeeded()
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
                refreshControl.centerYAnchor.constraint(equalTo: scrollView.safeAreaLayoutGuide.topAnchor,
                                                        constant: refreshControl.refreshHeight/2).isActive = true

                if !isRefreshing {
                    refreshControl.setNeedsLayout()
                    refreshControl.layoutIfNeeded()
                    refreshControl.refreshState = .none
                }
            }
        }
    }

    public var enableLoadMore: Bool = false {
        didSet {

            assert(moreLoader != nil, "Cannot change `enableLoadMore`. More Loader is not specified.")

            guard oldValue != enableLoadMore else {
                return
            }

            if enableLoadMore {
                scrollView.insertSubview(loadMoreControl, at: 0)
                loadMoreControl.translatesAutoresizingMaskIntoConstraints = false
                loadMoreControl.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
                loadMoreControl.centerYAnchor.constraint(equalTo: scrollView.safeAreaLayoutGuide.bottomAnchor,
                                                         constant: -loadMoreControl.refreshHeight/2).isActive = true

                if !isMoreLoading {
                    loadMoreControl.setNeedsLayout()
                    loadMoreControl.layoutIfNeeded()
                    loadMoreControl.refreshState = .none
                }
            } else {
                endLoadMoreAnimation()
                loadMoreControl.removeFromSuperview()
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
            loadMoreControl.centerYAnchor.constraint(equalTo: scrollView.safeAreaLayoutGuide.bottomAnchor,
                                                     constant: -loadMoreControl.refreshHeight/2).isActive = true

            if !isMoreLoading {
                loadMoreControl.setNeedsLayout()
                loadMoreControl.layoutIfNeeded()
                loadMoreControl.refreshState = .none
            }
        }
    }

    // MARK: - Private properties
    internal static var contentOffsetObserverContext: Int = 0
    internal static let hapticGenerator: UISelectionFeedbackGenerator = UISelectionFeedbackGenerator()
    internal static let impactGenerator: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    // MARK: - Public functions

    deinit {
        scrollView.removeObserver(self, forKeyPath: #keyPath(UIScrollView.contentOffset),
                                  context: &Self.contentOffsetObserverContext)
    }

    public init(scrollView: UIScrollView,
                refresher: Refreshable? = nil,
                moreLoader: MoreLoadable? = nil) {

        self.scrollView = scrollView
        self.refresher = refresher
        self.moreLoader = moreLoader

        let refreshControl: UIRefreshControl = UIRefreshControl()
        self.refreshControl = refreshControl

        let indicatorView: IQRefreshIndicatorView
        if #available(iOS 13.0, *) {
            indicatorView = IQRefreshIndicatorView(style: .medium)
        } else {
            indicatorView = IQRefreshIndicatorView(style: .gray)
            indicatorView.color = UIColor.darkGray
        }
        self.loadMoreControl = indicatorView

        defer {
            self.refreshControl.refreshState = .none
            self.loadMoreControl.refreshState = .none
            refreshControl.addTarget(self, action: #selector(self.refreshControlDidRefresh), for: .valueChanged)
            registerContentOffsetChangeObserver()
        }

        super.init()
    }
}

extension IQPullToRefresh {

    func registerContentOffsetChangeObserver() {
        contentOffsetObserver = scrollView.observe(\.contentOffset, changeHandler: { [weak self] _, _ in
            self?.handleContentOffsetChange()
        })
    }

    // swiftlint:disable cyclomatic_complexity
    // swiftlint:disable function_body_length
    private func handleContentOffsetChange() {

        let newOffset: CGPoint = scrollView.contentOffset
        var adjustedInset: UIEdgeInsets = scrollView.adjustedContentInset
        adjustedInset.top = adjustedInset.top.rounded(.down)
        adjustedInset.bottom = adjustedInset.bottom.rounded(.up)
        let contentSize: CGSize = scrollView.contentSize
        let scrollViewFrame: CGRect = scrollView.frame

        // Pull to refresh
        if enablePullToRefresh, refresher != nil, refreshControl.superview != nil, !isRefreshing {

            let finalTop: CGFloat = -(adjustedInset.top + refreshControl.refreshHeight)
            let offsetToPullToRefresh: CGFloat = finalTop + refreshControl.preloadOffset
            let finalOffset: CGFloat = (offsetToPullToRefresh + refreshControl.refreshHeight) - newOffset.y
            let estimatedProgress: CGFloat = finalOffset / refreshControl.refreshHeight

            let progress: CGFloat = max(0, min(1, estimatedProgress))

            if let refreshControl: UIRefreshControl = refreshControl as? UIRefreshControl {
                if !refreshControl.isRefreshing {
                    if scrollView.isDragging == true {
                        if newOffset.y <= (offsetToPullToRefresh + refreshControl.refreshHeight) {
                            if progress <= 0 {
                                refreshControl.refreshState = .none
                            } else if progress < 1 {
                                refreshControl.refreshState = .pulling(progress)
                            }
                        } else {
                            refreshControl.refreshState = .none
                        }
                    } else if scrollView.isDecelerating {
                        if progress == 0 {
                            refreshControl.refreshState = .none
                        } else {
                            refreshControl.refreshState = .pulling(progress)
                        }
                    } else if refreshControl.refreshState != .refreshing {
                        refreshControl.refreshState = .none
                    }
                }
            } else {
                if scrollView.isDragging == true {

                    if newOffset.y <= (offsetToPullToRefresh + refreshControl.refreshHeight) {
                        if progress >= 1 {
                            if refreshControl.refreshStyle == .progressCompletion {
                                Self.impactGenerator.impactOccurred()
                                beginPullToRefreshAnimation()
                                triggerSafeRefresh(type: .refreshControl)
                            } else if refreshControl.refreshState != .eligible {
                                refreshControl.refreshState = .pulling(progress)
                                refreshControl.refreshState = .eligible
                                Self.hapticGenerator.selectionChanged()
                            }
                        } else if progress <= 0 {
                            refreshControl.refreshState = .none
                        } else {
                            if refreshControl.refreshState == .eligible {
                                Self.hapticGenerator.selectionChanged()
                            }
                            refreshControl.refreshState = .pulling(progress)
                        }
                    } else {
                        refreshControl.refreshState = .none
                    }
                } else if scrollView.isDecelerating {

                    if refreshControl.refreshState == .eligible {
                        Self.impactGenerator.impactOccurred()
                        beginPullToRefreshAnimation()
                        triggerSafeRefresh(type: .refreshControl)
                    } else {
                        if progress == 0 {
                            refreshControl.refreshState = .none
                        } else {
                            refreshControl.refreshState = .pulling(progress)
                        }
                    }
                } else if refreshControl.refreshState != .refreshing {
                    refreshControl.refreshState = .none
                }
            }
        }

        // Load more
        if enableLoadMore,
           moreLoader != nil,
           loadMoreControl.superview != nil,
           !isMoreLoading,
           refreshControl.refreshState == .none {

            var offsetToLoadMore: CGFloat = 0
            if (contentSize.height + adjustedInset.top + adjustedInset.bottom) < scrollViewFrame.height {
                offsetToLoadMore = -adjustedInset.top - loadMoreControl.preloadOffset
            } else {
                let finalBottom: CGFloat = adjustedInset.bottom + contentSize.height - scrollViewFrame.height
                offsetToLoadMore = finalBottom - loadMoreControl.preloadOffset
            }

            if loadMoreControl.mode == .userInteraction {
                offsetToLoadMore += loadMoreControl.refreshHeight
            }

            let finalOffset: CGFloat = newOffset.y - (offsetToLoadMore - loadMoreControl.refreshHeight)
            let estimatedProgress: CGFloat = finalOffset / loadMoreControl.refreshHeight

            let progress: CGFloat = max(0, min(1, estimatedProgress))

            if scrollView.isDragging == true {

                if newOffset.y >= (offsetToLoadMore - loadMoreControl.refreshHeight) {
                    if progress >= 1 {
                        if loadMoreControl.refreshStyle == .progressCompletion {
                            Self.impactGenerator.impactOccurred()
                            beginLoadMoreAnimation()
                            triggerSafeLoadMore(type: .reachAtEnd)
                        } else if loadMoreControl.refreshState != .eligible {
                            loadMoreControl.refreshState = .pulling(progress)
                            loadMoreControl.refreshState = .eligible
                            Self.hapticGenerator.selectionChanged()
                        }
                    } else if progress <= 0 {
                        loadMoreControl.refreshState = .none
                    } else {
                        if loadMoreControl.refreshState == .eligible {
                            Self.hapticGenerator.selectionChanged()
                        }
                        loadMoreControl.refreshState = .pulling(progress)
                    }
                } else {
                    loadMoreControl.refreshState = .none
                }
            } else if scrollView.isDecelerating {
                if loadMoreControl.refreshState == .eligible {
                    Self.impactGenerator.impactOccurred()
                    beginLoadMoreAnimation()
                    triggerSafeLoadMore(type: .reachAtEnd)
                } else {
                    if progress == 0 || loadMoreControl.mode == .scrollLimitReached {
                        loadMoreControl.refreshState = .none
                    } else {
                        loadMoreControl.refreshState = .pulling(progress)
                    }
                }
            } else if loadMoreControl.refreshState != .refreshing {
                loadMoreControl.refreshState = .none
            }
        }
    }
    // swiftlint:enable cyclomatic_complexity
}
