//
//  IQAnimatableRefresh.swift
//  IQPullToRefresh
//
//  Created by Iftekhar on 08/02/21.
//

import UIKit

public protocol IQAnimatableRefresh where Self: UIView {

    var isRefreshing: Bool { get }

    var progress: CGFloat { get set }

    func beginRefreshing()

    func endRefreshing()
}

extension UIActivityIndicatorView: IQAnimatableRefresh {
    public var isRefreshing: Bool {
        return isAnimating
    }

    public var progress: CGFloat {
        get {
            return alpha
        }
        set {
            print("Progress: \(progress)")
            
            alpha = newValue
            if newValue <= 0 {
                isHidden = true
            } else {
                isHidden = false
            }
        }
    }

    public func beginRefreshing() {
        progress = 1
        startAnimating()

        UIView.animate(withDuration: 0.1, delay: 0, options: .beginFromCurrentState, animations: { [weak self] in
            self?.transform = .init(scaleX: 1.2, y: 1.2)
        }, completion: { [weak self] success in
            UIView.animate(withDuration: 2, delay: 0, options: [.beginFromCurrentState, .curveEaseOut], animations: { [weak self] in
                self?.transform = .init(rotationAngle: CGFloat.pi)
            }, completion:nil)
        })
    }

    public func endRefreshing() {
        progress = 0
        stopAnimating()

        UIView.animate(withDuration: 0.1, delay: 0, options: .beginFromCurrentState, animations: { [weak self] in
            self?.transform = .identity
        })
    }
}

extension UIRefreshControl: IQAnimatableRefresh {
    public var progress: CGFloat {
        get {
            return 0
        }
        set {
        }
    }
}

