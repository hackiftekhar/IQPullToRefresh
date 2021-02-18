//
//  PreloadActivityIndicatorView.swift
//  Pull To Refresh Demo
//
//  Created by Iftekhar on 18/02/21.
//

import UIKit
import IQPullToRefresh

class PreloadActivityIndicatorView: UIActivityIndicatorView, IQAnimatableRefresh {

    public var refreshStyle: IQRefreshTriggerStyle {
        return .progressCompletion
    }

    var preloadOffset: CGFloat {
        return 500
    }

    var refreshHeight: CGFloat {
        return 40
    }

    public var refreshState: IQAnimatableRefreshState = .unknown {
        didSet {

            guard oldValue != refreshState else {
                return
            }

            switch refreshState {
            case .unknown, .none:

                UIView.animate(withDuration: 0.2, delay: 0, options: .beginFromCurrentState, animations: { [weak self] in
                    self?.alpha = 0
                    self?.transform = .identity
                }, completion: nil)

                if isAnimating {
                    stopAnimating()
                }

            case .pulling(let progress):

                UIView.animate(withDuration: 0.1, delay: 0, options: .beginFromCurrentState, animations: { [weak self] in
                    self?.transform = .identity
                    self?.alpha = progress
                }, completion: nil)

            case .eligible:

                UIView.animate(withDuration: 0.1, delay: 0, options: .beginFromCurrentState, animations: { [weak self] in
                    self?.transform = .init(scaleX: 1.5, y: 1.5)
                    self?.alpha = 1
                }, completion: nil)

            case .refreshing:

                alpha = 1

                if !isAnimating {
                    startAnimating()

                    UIView.animate(withDuration: 2, delay: 0, options: [.beginFromCurrentState, .curveEaseOut], animations: { [weak self] in
                        self?.transform = .init(rotationAngle: CGFloat.pi)
                    }, completion:nil)
                }
            }
        }
    }

    public override init(style: UIActivityIndicatorView.Style) {
        super.init(style: style)
        hidesWhenStopped = false
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
