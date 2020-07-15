//
//  SceneDelegate.swift
//  Bonfire
//
//  Created by James Dale on 19/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit
import BFNetworking

@available(iOS 13.0, *)
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let scene = (scene as? UIWindowScene) else { return }
        
        KeychainVault.accessToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImp0aSI6IjAtMS00NjcyOC0xNTk0NzcxNjc1NDU0MDc0NjExNjEzNjA2NjI0NSJ9.eyJpc3MiOiJSb29tcy1BUEktSW50ZXJuYWwtQWNjZXNzIiwiYXVkIjoiYzgyZjU2NDUtODgzNi00OGQwLWU0YzItNGEyMTUxMzE3Yjk3IiwiaWF0IjoxNTk0NzcxNjc1LCJqdGkiOiIwLTEtNDY3MjgtMTU5NDc3MTY3NTQ1NDA3NDYxMTYxMzYwNjYyNDUiLCJleHAiOjE1OTQ4NTgwNzUsInVpZCI6MSwibGlkIjoyNDM2NywiYXRpZCI6NDY3MjgsInR5cGUiOiJhY2Nlc3MiLCJzY29wZSI6InVzZXJzLHBvc3RzLGNhbXBzIiwidiI6MX0.oZ0opCYxvUeAHzK5O_yQrLDFYBikLBTDaP3T0WF9_qI"
        
        let tabVC = BFTabBarController()
        
        let friendsVC = FriendsViewController()
        let friendsNavVC = BFNavigationController(rootViewController: friendsVC)
        friendsVC.tabBarItem = FriendsViewController.defaultTabBarItem
        
        let homeVC = HomeViewController()
        let homeNavVC = BFNavigationController(rootViewController: homeVC)
        homeVC.tabBarItem = HomeViewController.defaultTabBarItem
        
        let campsVC = CampsViewController()
        let campsNavVC = BFNavigationController(rootViewController: campsVC)
        campsVC.tabBarItem = CampsViewController.defaultTabBarItem
        
        tabVC.setViewControllers([friendsNavVC, homeNavVC, campsNavVC], animated: false)
        
        tabVC.selectedViewController = homeNavVC
        
        let window = UIWindow(windowScene: scene)
        window.rootViewController = tabVC
        window.makeKeyAndVisible()
        self.window = window
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

