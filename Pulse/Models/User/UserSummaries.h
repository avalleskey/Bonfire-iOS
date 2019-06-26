//
//  UserSummaries.h
//  Pulse
//
//  Created by Austin Valleskey on 12/11/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "JSONModel.h"

@class UserSummaries;
@class UserSummariesCounts;

@interface UserSummaries : JSONModel

@property (nonatomic) UserSummariesCounts <Optional> *counts;

@end

@interface UserSummariesCounts : JSONModel

@property (nonatomic) NSInteger posts;
@property (nonatomic) NSInteger camps;
@property (nonatomic) NSInteger following;

@end
