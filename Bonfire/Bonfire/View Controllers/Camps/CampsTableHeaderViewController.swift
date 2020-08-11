//
//  CampsTableHeaderViewController.swift
//  Bonfire
//
//  Created by James Dale on 11/8/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

final class CampsTableHeaderViewController: UICollectionViewController {
    
    let cellType: UICollectionViewCell
    
    init(cellType: UICollectionViewCell) {
        self.cellType = cellType
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
