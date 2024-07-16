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

@MainActor
public final class IQPullToRefresh: NSObject {

    // MARK: - Public properties

    public private(set) var scrollView: UIScrollView

    public weak var refresher: (any Refreshable)?
    public weak var moreLoader: (any MoreLoadable)?

    internal let scrollDirection: UICollectionView.ScrollDirection

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

                    let refreshLength = refreshControl.refreshLength
                    if scrollDirection == .horizontal {
                        refreshControl.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor).isActive = true
                        refreshControl.centerXAnchor.constraint(equalTo: scrollView.safeAreaLayoutGuide.leadingAnchor,
                                                                constant: refreshLength/2).isActive = true
                    } else {
                        refreshControl.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
                        refreshControl.centerYAnchor.constraint(equalTo: scrollView.safeAreaLayoutGuide.topAnchor,
                                                                constant: refreshLength/2).isActive = true
                    }

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

    public var refreshControl: any IQAnimatableRefresh {
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
                if scrollDirection == .horizontal {
                    refreshControl.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor).isActive = true
                    refreshControl.centerXAnchor.constraint(equalTo: scrollView.safeAreaLayoutGuide.leadingAnchor,
                                                            constant: refreshControl.refreshLength/2).isActive = true
                } else {
                    refreshControl.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
                    refreshControl.centerYAnchor.constraint(equalTo: scrollView.safeAreaLayoutGuide.topAnchor,
                                                            constant: refreshControl.refreshLength/2).isActive = true
                }

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
                if scrollDirection == .horizontal {
                    loadMoreControl.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor).isActive = true
                    loadMoreControl.centerXAnchor.constraint(equalTo: scrollView.safeAreaLayoutGuide.trailingAnchor,
                                                             constant: -loadMoreControl.refreshLength/2).isActive = true
                } else {
                    loadMoreControl.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
                    loadMoreControl.centerYAnchor.constraint(equalTo: scrollView.safeAreaLayoutGuide.bottomAnchor,
                                                             constant: -loadMoreControl.refreshLength/2).isActive = true
                }
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

    public var loadMoreControl: any IQAnimatableRefresh {
        didSet {
            guard enableLoadMore else {
                return
            }

            oldValue.removeFromSuperview()
            scrollView.insertSubview(loadMoreControl, at: 0)
            loadMoreControl.translatesAutoresizingMaskIntoConstraints = false
            if scrollDirection == .horizontal {
                loadMoreControl.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor).isActive = true
                loadMoreControl.centerXAnchor.constraint(equalTo: scrollView.safeAreaLayoutGuide.trailingAnchor,
                                                         constant: -loadMoreControl.refreshLength/2).isActive = true
            } else {
                loadMoreControl.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
                loadMoreControl.centerYAnchor.constraint(equalTo: scrollView.safeAreaLayoutGuide.bottomAnchor,
                                                         constant: -loadMoreControl.refreshLength/2).isActive = true
            }
            if !isMoreLoading {
                loadMoreControl.setNeedsLayout()
                loadMoreControl.layoutIfNeeded()
                loadMoreControl.refreshState = .none
            }
        }
    }

    // MARK: - Private properties
    internal static let hapticGenerator: UISelectionFeedbackGenerator = UISelectionFeedbackGenerator()
    internal static let impactGenerator: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    // MARK: - Public functions

    deinit {
        contentOffsetObserver?.invalidate()
        contentOffsetObserver = nil
    }

    public init(scrollView: UIScrollView,
                refresher: (any Refreshable)? = nil,
                moreLoader: (any MoreLoadable)? = nil) {

        self.scrollView = scrollView
        self.refresher = refresher
        self.moreLoader = moreLoader

        if let collectionView = scrollView as? UICollectionView {
            if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                scrollDirection = layout.scrollDirection
            } else if let layout = collectionView.collectionViewLayout as? UICollectionViewCompositionalLayout {
                scrollDirection = layout.configuration.scrollDirection
            } else {
                scrollDirection = .vertical
            }
        } else {
            scrollDirection = .vertical
        }

        if scrollDirection == .horizontal {
            let indicatorView: IQRefreshIndicatorView = IQRefreshIndicatorView(style: .medium)
            self.refreshControl = indicatorView
        } else {
            let refreshControl: UIRefreshControl = UIRefreshControl()
            self.refreshControl = refreshControl
        }

        do {
            let indicatorView: IQRefreshIndicatorView = IQRefreshIndicatorView(style: .medium)
            self.loadMoreControl = indicatorView
        }

        defer {
            self.refreshControl.refreshState = .none
            self.loadMoreControl.refreshState = .none

            if let refreshControl = refreshControl as? UIRefreshControl {
                refreshControl.addTarget(self, action: #selector(self.refreshControlDidRefresh), for: .valueChanged)
            }

            registerContentOffsetChangeObserver()
        }

        super.init()
    }
}

@MainActor
extension IQPullToRefresh {

    func registerContentOffsetChangeObserver() {

        contentOffsetObserver = scrollView.observe(\.contentOffset, changeHandler: { [weak self] _, _ in
            guard let self = self else { return }

            MainActor.assumeIsolatedBackDeployed {
                self.handleContentOffsetChange()
            }
        })
    }

    // swiftlint:disable cyclomatic_complexity
    // swiftlint:disable function_body_length
    private func handleContentOffsetChange() {

        let newOffset: CGPoint = scrollView.contentOffset
        var adjustedInset: UIEdgeInsets = scrollView.adjustedContentInset
        adjustedInset.left = adjustedInset.left.rounded(.down)
        adjustedInset.right = adjustedInset.right.rounded(.up)
        adjustedInset.top = adjustedInset.top.rounded(.down)
        adjustedInset.bottom = adjustedInset.bottom.rounded(.up)
        let contentSize: CGSize = scrollView.contentSize
        let scrollViewFrame: CGRect = scrollView.frame

        // Pull to refresh
        if enablePullToRefresh, refresher != nil, refreshControl.superview != nil, !isRefreshing {

            let offsetToPullToRefresh: CGFloat
            let offsetToValidate: CGFloat

            if scrollDirection == .horizontal {
                let finalTop: CGFloat = -(adjustedInset.left + refreshControl.refreshLength)
                offsetToPullToRefresh = finalTop + refreshControl.preloadOffset
                offsetToValidate = newOffset.x
            } else {
                let finalTop: CGFloat = -(adjustedInset.top + refreshControl.refreshLength)
                offsetToPullToRefresh = finalTop + refreshControl.preloadOffset
                offsetToValidate = newOffset.y
            }

            let finalOffset: CGFloat = (offsetToPullToRefresh + refreshControl.refreshLength) - offsetToValidate
            let estimatedProgress: CGFloat = finalOffset / refreshControl.refreshLength
            let progress: CGFloat = max(0, min(1, estimatedProgress))

            if let refreshControl: UIRefreshControl = refreshControl as? UIRefreshControl {
                if !refreshControl.isRefreshing {
                    if scrollView.isDragging == true {
                        if offsetToValidate <= (offsetToPullToRefresh + refreshControl.refreshLength) {
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

                    if offsetToValidate <= (offsetToPullToRefresh + refreshControl.refreshLength) {
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
            let offsetToValidate: CGFloat

            if scrollDirection == .horizontal {
                if (contentSize.width + adjustedInset.left + adjustedInset.right) < scrollViewFrame.width {
                    offsetToLoadMore = -adjustedInset.left - loadMoreControl.preloadOffset
                } else {
                    let finalBottom: CGFloat = adjustedInset.right + contentSize.width - scrollViewFrame.width
                    offsetToLoadMore = finalBottom - loadMoreControl.preloadOffset
                }

                offsetToValidate = newOffset.x
            } else {
                if (contentSize.height + adjustedInset.top + adjustedInset.bottom) < scrollViewFrame.height {
                    offsetToLoadMore = -adjustedInset.top - loadMoreControl.preloadOffset
                } else {
                    let finalBottom: CGFloat = adjustedInset.bottom + contentSize.height - scrollViewFrame.height
                    offsetToLoadMore = finalBottom - loadMoreControl.preloadOffset
                }

                offsetToValidate = newOffset.y
            }

            if loadMoreControl.mode == .userInteraction {
                offsetToLoadMore += loadMoreControl.refreshLength
            }

            let finalOffset: CGFloat = offsetToValidate - (offsetToLoadMore - loadMoreControl.refreshLength)
            let estimatedProgress: CGFloat = finalOffset / loadMoreControl.refreshLength
            let progress: CGFloat = max(0, min(1, estimatedProgress))

            if scrollView.isDragging == true {

                if offsetToValidate >= (offsetToLoadMore - loadMoreControl.refreshLength) {
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
    // swiftlint:enable function_body_length
}
