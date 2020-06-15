//
//  BFAPI.swift
//  Pulse
//
//  Created by James Dale on 16/6/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

import Foundation
import FirebaseAnalytics

@objc(BFAPI_Swift)
class BFAPI_Swift: NSObject {
    
    @objc static let shared = BFAPI_Swift()
    private override init() {}
    
    @objc func blockIdentity(identity: Identity, handler: @escaping((Bool, Any) -> Void)) {
        NSLog("[SwiftFire] %@", "Block User Started")
        Analytics.logEvent("block_user", parameters: [:])
        let url = "users/\(identity.identifier)/block"
        
        HAWebService.authenticatedManager().post(url, parameters: nil, success: { (task, responseObject) in
            NSLog("--------");
            NSLog("success: blockUser");
            NSLog("--------");
            //
            handler(true, ["blocked": true])
        }) { (task, error) in
            NSLog("error: %@", error.localizedDescription)
            handler(false, ["error": error])
        }
    }
    
    @objc func getUser(handler: ((Bool, User) -> Void)?) {
        NSLog("[SwiftFire] %@", "Get User Started")
        let url = "users/me"
        HAWebService.authenticatedManager().get(url, parameters: nil, success: { (task, responseObject) in
            guard let responseObject = responseObject as? [AnyHashable: Any],
                let data = responseObject["data"] as? [AnyHashable: Any]
                else { return }
            
            do {
                let user = try User(dictionary: data)
                handler?(true, user)
            } catch {
                NSLog("GET -> /users/me; User error: %@", error.localizedDescription);
            }
            
        }) { (task, error) in
            NSLog("❌ Failed to get User ID");
            NSLog("%@", error.localizedDescription);
            handler?(false, User())
        }
    }
    
    @objc func followUser(user: User, handler: @escaping ((Bool, Any?) -> Void)) {
        NSLog("[SwiftFire] %@", "Follow User Started")
        Analytics.logEvent("follow_user", parameters: [:])
        
        let url = "users/\(user.identifier)/follow"
        
        HAWebService.authenticatedManager().post(url, parameters: nil, success: { (task, responseObject) in
            NSLog("--------");
            NSLog("success: followUser");
            NSLog("--------");
            NotificationCenter.default.post(name: .init(rawValue: "FetchNewTimelinePosts"),
                                            object: nil)
            handler(true, ["following": true])
            
        }) { (task, error) in
            NSLog("error: %@", error.localizedDescription)
            handler(false, error)
        }
    }
    
    @objc func unfollowUser(user: User, handler: @escaping ((Bool, Any?) -> Void)) {
        NSLog("[SwiftFire] %@", "Unfollow User Started")
        Analytics.logEvent("unfollow_user", parameters: [:])
        
        let url = "users/\(user.identifier)/follow"
        HAWebService.authenticatedManager().delete(url, parameters: nil, success: { (task, responseObject) in
            NSLog("--------");
            NSLog("success: unfollowUser");
            NSLog("--------");
            
            handler(true, ["following": false])
        }) { (task, error) in
            NSLog("%@", error.localizedDescription)
            handler(false, ["error": error])
        }
    }
}
