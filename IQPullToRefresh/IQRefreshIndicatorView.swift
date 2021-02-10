//
//  IQRefreshIndicatorView.swift
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

private var kRefreshState = "refreshState"

public class IQRefreshIndicatorView: UIActivityIndicatorView, IQAnimatableRefresh {

    public var refreshHeight: CGFloat {
        return 60
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

