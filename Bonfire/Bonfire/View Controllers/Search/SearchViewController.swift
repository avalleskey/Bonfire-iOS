//
//  SearchViewController.swift
//  Bonfire
//
//  Created by James Dale on 12/8/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

final class BFSearchController: UISearchController {

    override init(searchResultsController: UIViewController?) {
        super.init(searchResultsController: searchResultsController)
        view.backgroundColor = Constants.Color.systemBackground
        searchBar.backgroundColor = Constants.Color.systemBackground
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes =
            [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18, weight: .bold).rounded()]

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
