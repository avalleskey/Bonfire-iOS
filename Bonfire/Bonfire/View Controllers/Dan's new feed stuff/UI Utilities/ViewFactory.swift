//
//  ViewFactory.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-08-19.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit
import Cartography

extension UIFont {
    var dynamic: UIFont { UIFontMetrics.metrics(forSize: self.pointSize).scaledFont(for: self) }
}

extension UIFontMetrics {
    static func metrics(forSize size: CGFloat) -> UIFontMetrics {
        switch size {
        case _ where size <= 11:
            return UIFontMetrics(forTextStyle: .caption2)
        case 12:
            return UIFontMetrics(forTextStyle: .caption1)
        case 13...14:
            return UIFontMetrics(forTextStyle: .footnote)
        case 15:
            return UIFontMetrics(forTextStyle: .subheadline)
        case 16:
            return UIFontMetrics(forTextStyle: .callout)
        case 17...19:
            return UIFontMetrics(forTextStyle: .body)
        case 20...21:
            return UIFontMetrics(forTextStyle: .title3)
        case 22...27:
            return UIFontMetrics(forTextStyle: .title2)
        case 28...33:
            return UIFontMetrics(forTextStyle: .title1)
        case _ where size >= 34:
            return UIFontMetrics(forTextStyle: .largeTitle)
        default:
            return UIFontMetrics(forTextStyle: .body)
        }
    }
}

extension UIButton {

    convenience init(image: UIImage? = nil,
                     contentColor: UIColor? = nil,
                     backgroundColor: UIColor = .clear,
                     title: String? = nil,
                     textFormat: (size: CGFloat, weight: UIFont.Weight)? = nil,
                     width: CGFloat? = nil,
                     height: CGFloat? = nil,
                     cornerRadius: CGFloat = 0.0,
                     padding: CGFloat = 0,
                     systemButton: Bool = true,
                     dynamicTextSize: Bool = false) {

        self.init(type: systemButton ? .system : .custom)
        translatesAutoresizingMaskIntoConstraints = false
        if let image = image { setImage(image, for: .normal) }
        if let contentColor = contentColor {
            tintColor = contentColor
            setTitleColor(contentColor, for: .normal)
        }
        self.backgroundColor = backgroundColor
        if let title = title { setTitle(title, for: .normal) }
        if let textFormat = textFormat {
            if dynamicTextSize {
                titleLabel?.font = UIFont.systemFont(ofSize: textFormat.size, weight: textFormat.weight).dynamic.rounded()
                titleLabel?.adjustsFontForContentSizeCategory = true
            } else {
                titleLabel?.font = UIFont.systemFont(ofSize: textFormat.size, weight: textFormat.weight).rounded()
            }
        }

        constrain(self) {
            if let width = width { $0.width == width }
            if let height = height { $0.height == height }
        }

        layer.cornerRadius = cornerRadius
        contentEdgeInsets = UIEdgeInsets(top: 0.0, left: padding, bottom: 0.0, right: padding)

        if image != nil && title != nil {
            contentEdgeInsets = UIEdgeInsets(top: 0, left: contentEdgeInsets.left + 4, bottom: 0, right: contentEdgeInsets.right + 8)
            titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
        }
    }
}

extension UILabel {

    convenience init(size: CGFloat,
                     weight: UIFont.Weight,
                     color: UIColor = Constants.Color.primary,
                     alignment: NSTextAlignment = .left,
                     multiline: Bool = true,
                     dynamicTextSize: Bool = false,
                     text: String? = nil) {

        self.init()
        translatesAutoresizingMaskIntoConstraints = false
        if dynamicTextSize {
            font = UIFont.systemFont(ofSize: size, weight: weight).dynamic.rounded()
            adjustsFontForContentSizeCategory = true
        } else {
            font = UIFont.systemFont(ofSize: size, weight: weight).rounded()
        }

        textColor = color
        if let text = text { self.text = text }
        if multiline { numberOfLines = 0 }
        textAlignment = alignment
    }
}

extension UIStackView {

    convenience init(axis: NSLayoutConstraint.Axis,
                     alignment: UIStackView.Alignment = .fill,
                     distribution: UIStackView.Distribution = .fill,
                     spacing: CGFloat = 0.0) {

        self.init()
        translatesAutoresizingMaskIntoConstraints = false
        self.axis = axis
        self.alignment = alignment
        self.distribution = distribution
        self.spacing = spacing
    }
}

extension UIView {

    convenience init(backgroundColor: UIColor = .clear,
                     alpha: CGFloat = 1.0,
                     borderColor: UIColor = .clear,
                     borderWidth: CGFloat = 0.0,
                     height: CGFloat? = nil,
                     width: CGFloat? = nil,
                     cornerRadius: CGFloat = 0.0,
                     shadowIntensity: ShadowIntensity = .none) {

        self.init()
        translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = backgroundColor
        self.alpha = alpha
        layer.borderColor = borderColor.cgColor
        layer.borderWidth = borderWidth
        layer.cornerRadius = cornerRadius

        constrain(self) {
            if let width = width { $0.width == width }
            if let height = height { $0.height == height }
        }

        if shadowIntensity != .none { applyShadow(explicitPath: false, intensity: shadowIntensity) }
    }
}

extension UITextView {

    convenience init(textSize: CGFloat,
                     textWeight: UIFont.Weight,
                     textColor: UIColor = Constants.Color.primary,
                     backgroundColor: UIColor = .clear,
                     tintColor: UIColor? = nil,
                     isScrollable: Bool = false,
                     returnKeyType: UIReturnKeyType = .default,
                     dynamicTextSize: Bool = false) {

        self.init()
        translatesAutoresizingMaskIntoConstraints = false

        if dynamicTextSize {
            font = UIFont.systemFont(ofSize: textSize, weight: textWeight).dynamic.rounded()
            adjustsFontForContentSizeCategory = true
        } else {
            font = UIFont.systemFont(ofSize: textSize, weight: textWeight).rounded()
        }


        self.textColor = textColor
        self.backgroundColor = backgroundColor
        if let tintColor = tintColor { self.tintColor = tintColor }
        isScrollEnabled = isScrollable
        textContainer.lineFragmentPadding = 0.0
        textContainerInset = UIEdgeInsets.zero
        self.returnKeyType = returnKeyType
    }
}

extension UITextField {

    convenience init(textSize: CGFloat,
                     textWeight: UIFont.Weight,
                     textColor: UIColor = Constants.Color.primary,
                     placeholderText: String = "",
                     leftImage: UIImage? = nil,
                     padding: CGFloat = 0,
                     backgroundColor: UIColor = Constants.Color.secondaryFill,
                     borderColor: UIColor = .clear,
                     borderWidth: CGFloat = 0.0,
                     cornerRadius: CGFloat = 12.0,
                     tintColor: UIColor? = nil,
                     height: CGFloat? = nil,
                     dynamicTextSize: Bool = false) {

        self.init()
        translatesAutoresizingMaskIntoConstraints = false

        if dynamicTextSize {
            font = UIFont.systemFont(ofSize: textSize, weight: textWeight).dynamic.rounded()
            adjustsFontForContentSizeCategory = true
        } else {
            font = UIFont.systemFont(ofSize: textSize, weight: textWeight).rounded()
        }

        placeholder = placeholderText
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        layer.borderWidth = borderWidth
        layer.borderColor = borderColor.cgColor
        layer.cornerRadius = cornerRadius
        if let height = height {
            constrain(self) { $0.height == height }
        }

        if let leftImage = leftImage {
            let paddingView = UIImageView(image: leftImage)
            paddingView.translatesAutoresizingMaskIntoConstraints = false
            paddingView.widthAnchor.constraint(equalToConstant: 40.0).isActive = true
            paddingView.heightAnchor.constraint(equalToConstant: height ?? 44).isActive = true
            paddingView.contentMode = .center
            paddingView.tintColor = Constants.Color.secondary
            leftView = paddingView
            leftViewMode = .always
        } else {
            let paddingView = UIView()
            constrain(paddingView) {
                $0.width == padding
                $0.height == height ?? 44
            }
            leftView = paddingView
            leftViewMode = .always
        }

        if let tintColor = tintColor {
            self.tintColor = tintColor
        }

        self.returnKeyType = .done
    }
}

extension UIImageView {

    convenience init(image: UIImage? = nil, tintColor: UIColor? = nil, width: CGFloat? = nil, height: CGFloat? = nil, cornerRadius: CGFloat = 0, contentMode: UIView.ContentMode? = nil) {
        self.init(image: image)
        translatesAutoresizingMaskIntoConstraints = false
        self.tintColor = tintColor
        if let contentMode = contentMode { self.contentMode = contentMode }
        if cornerRadius != 0 {
            clipsToBounds = true
            layer.cornerRadius = cornerRadius
        }


        constrain(self) {
            if let width = width { $0.width == width }
            if let height = height { $0.height == height }
        }
    }
}

extension UIActivityIndicatorView {
    convenience init(style: UIActivityIndicatorView.Style, color: UIColor? = nil, isAnimating: Bool = false, hidesWhenStopped: Bool = true) {
        self.init(style: style)
        translatesAutoresizingMaskIntoConstraints = false
        if let color = color { self.color = color }
        self.hidesWhenStopped = hidesWhenStopped
        if isAnimating { startAnimating() }
    }
}

extension UIScrollView {
    static func make(backgroundColor: UIColor? = nil, intrinsicallySized: Bool = false, topOffset: CGFloat = 0) -> UIScrollView {
        let scrollView: UIScrollView
        if intrinsicallySized {
            scrollView = IntrinsicallySizedScrollView()
        } else {
            scrollView = UIScrollView()
        }
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        if let backgroundColor = backgroundColor {
            scrollView.backgroundColor = backgroundColor
        }
        return scrollView
    }
}

extension UITableView {
    static func make(backgroundColor: UIColor = Constants.Color.systemBackground, cellReuseIdentifier: String, cellClass: AnyClass = UITableViewCell.self, intrinsicallySized: Bool = false, allowsSelection: Bool = false, showSeparators: Bool = false, topOffset: CGFloat = 0) -> UITableView {
        let tableView: UITableView
        if intrinsicallySized {
            tableView = IntrinsicallySizedTableView()
        } else {
            tableView = UITableView()
        }

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(cellClass, forCellReuseIdentifier: cellReuseIdentifier)
        tableView.allowsSelection = allowsSelection
        tableView.tableFooterView = UIView()
        if topOffset > 0 { tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: topOffset)) }

        tableView.keyboardDismissMode = .onDrag
        tableView.separatorStyle = showSeparators ? .singleLine : .none
        tableView.backgroundColor = backgroundColor
        return tableView
    }
}

extension UICollectionView {
    static func make(cellReuseIdentifier: String, cellClass: AnyClass = UICollectionViewCell.self, intrinsicallySized: Bool = false, allowsSelection: Bool = false, scrollDirection: UICollectionView.ScrollDirection = .vertical, customLayout: UICollectionViewLayout? = nil) -> UICollectionView {
        let collectionView: UICollectionView

        var layout: UICollectionViewLayout
        if let customLayout = customLayout {
            layout = customLayout
        } else {
            let flowLayout = UICollectionViewFlowLayout()
            flowLayout.scrollDirection = scrollDirection
            layout = flowLayout
        }

        if intrinsicallySized {
            collectionView = IntrinsicallySizedCollectionView(frame: .zero, collectionViewLayout: layout)
        } else {
            collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        }

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(cellClass, forCellWithReuseIdentifier: cellReuseIdentifier)
        collectionView.allowsSelection = allowsSelection
        return collectionView
    }
}

