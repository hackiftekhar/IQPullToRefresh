//
//  CustomPullToRefresh.swift
//  Pull To Refresh Demo
//
//  Created by Iftekhar on 10/02/21.
//

import UIKit
import IQPullToRefresh

class CustomPullToRefresh: UIView, IQAnimatableRefresh {

    var refreshLength: CGFloat {
        return 80
    }

    var refreshState: IQAnimatableRefreshState = .unknown {
        didSet {
            guard refreshState != oldValue else {
                return
            }

            switch refreshState {
            case .unknown, .none:
                let frame = self.frame
                UIView.animate(withDuration: 0.2, animations: { [weak self] in
                    self?.alpha = 0
                    self?.transform = .init(translationX: 0, y: -frame.height)
                }, completion: nil)
                activityIndicatorView.stopAnimating()
            case .pulling(let progress):
                let frame = self.frame
                UIView.animate(withDuration: 0.2, animations: { [weak self] in
                    self?.alpha = 1
                    self?.transform = .init(translationX: 0, y: (frame.height * progress) - frame.height)

                    let color = UIColor.systemRed

                    self?.imageView.tintColor = color
                    self?.imageView.isHidden = false
                    self?.imageView.transform = .init(rotationAngle: CGFloat.pi * progress)

                    self?.label.text = "Pull to refresh"
                    self?.label.textColor = color

                }, completion: nil)
            case .eligible:
                UIView.animate(withDuration: 0.2, animations: { [weak self] in
                    self?.alpha = 1
                    self?.transform = .identity

                    let color = UIColor.systemBlue

                    self?.imageView.tintColor = color
                    self?.imageView.isHidden = false
                    self?.imageView.transform = .init(rotationAngle: .pi)

                    self?.label.text = "Release to refresh"
                    self?.label.textColor = color

                }, completion: nil)

            case .refreshing:
                UIView.animate(withDuration: 0.2, animations: { [weak self] in
                    self?.alpha = 1
                    self?.transform = .identity

                    let color = UIColor.systemGreen

                    self?.activityIndicatorView.color = color

                    self?.imageView.isHidden = true
                    self?.imageView.tintColor = color

                    self?.label.text = "Loading"
                    self?.label.textColor = color

                }, completion: nil)

                activityIndicatorView.startAnimating()
            }
        }
    }

    let imageView = UIImageView(image: UIImage(named: "arrow"))
    let label = UILabel()
    let activityIndicatorView = UIActivityIndicatorView(style: .medium)
    let stackView = UIStackView()
    override init(frame: CGRect) {
        super.init(frame: frame)

        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .center
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(activityIndicatorView)
        stackView.addArrangedSubview(label)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(stackView)

        stackView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

        alpha = 0
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        var intrinsicContentSize = super.intrinsicContentSize
        intrinsicContentSize.height = refreshLength
        return intrinsicContentSize
    }
}
