//
//  InteractionControlling.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-09-11.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

protocol InteractionControlling: UIViewControllerInteractiveTransitioning {
    var interactionInProgress: Bool { get }
}
