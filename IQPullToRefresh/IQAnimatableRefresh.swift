//
//  IQAnimatableRefresh.swift
//  IQPullToRefresh
//
//  Created by Iftekhar on 08/02/21.
//

import UIKit

public enum IQAnimatableRefreshState: Equatable {
    case none
    case pulling(CGFloat)
    case eligible
    case refreshing
}

public protocol IQAnimatableRefresh where Self: UIView {

    var refreshHeight: CGFloat { get }
    var refreshState: IQAnimatableRefreshState { get set }
}

private var kRefreshState = "refreshState"

extension UIActivityIndicatorView: IQAnimatableRefresh {

    public var refreshHeight: CGFloat {
        return 60
    }

    public var refreshState: IQAnimatableRefreshState {
        get {
            return objc_getAssociatedObject(self, &kRefreshState) as? IQAnimatableRefreshState ?? .none
        }
        set {
            guard refreshState != newValue else {
                return
            }

            objc_setAssociatedObject(self, &kRefreshState, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)

            changeState(newState: newValue)
        }
    }

    public func changeState(newState: IQAnimatableRefreshState) {

        switch newState {
        case .none:

            UIView.animate(withDuration: 0.2, delay: 0, options: .beginFromCurrentState, animations: { [weak self] in
                self?.alpha = 0
            }, completion: nil)

            if isAnimating {
                stopAnimating()

                UIView.animate(withDuration: 0.1, delay: 0, options: .beginFromCurrentState, animations: { [weak self] in
                    self?.transform = .identity
                })
            }

        case .pulling(let progress):

            alpha = progress
            color = UIColor.black

        case .eligible:

            alpha = 1
            color = UIColor.green

        case .refreshing:

            alpha = 1
            color = UIColor.blue

            if !isAnimating {
                startAnimating()

                UIView.animate(withDuration: 0.1, delay: 0, options: .beginFromCurrentState, animations: { [weak self] in
                    self?.transform = .init(scaleX: 1.2, y: 1.2)
                }, completion: { [weak self] success in
                    UIView.animate(withDuration: 2, delay: 0, options: [.beginFromCurrentState, .curveEaseOut], animations: { [weak self] in
                        self?.transform = .init(rotationAngle: CGFloat.pi)
                    }, completion:nil)
                })
            }
        }
    }
}

extension UIRefreshControl: IQAnimatableRefresh {

    public var refreshHeight: CGFloat {
        return -1
    }

    public var refreshState: IQAnimatableRefreshState {
        get {
            return objc_getAssociatedObject(self, &kRefreshState) as? IQAnimatableRefreshState ?? .none
        }
        set {
            objc_setAssociatedObject(self, &kRefreshState, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

