//
//  CampSummaries.swift
//  Pulse
//
//  Created by James Dale on 15/6/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

import Foundation

@objc class CampSummaries: BFJSONModel {
    @objc var members: [User]!
    
    @objc var counts: CampCounts?
    
    required init(dictionary dict: [AnyHashable : Any]!) throws {
        super.init()
        
        print("[JD3]", dict)
        if let countsDict = dict["counts"] as? [AnyHashable: Any] {
            let counts = try CampCounts(dictionary: countsDict)
            
            self.counts = counts
        }
        
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init(data: Data!) throws {
        fatalError("init(data:) has not been implemented")
    }
}

//@interface CampSummaries : BFJSONModel
//
//@property (nonatomic) NSArray <User *> <User, Optional> *members;
//@property (nonatomic) CampCounts <Optional> *counts;
//
//@end
