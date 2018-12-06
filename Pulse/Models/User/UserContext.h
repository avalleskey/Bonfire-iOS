//
//  UserContext.h
//  Pulse
//
//  Created by Austin Valleskey on 10/21/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <JSONModel/JSONModel.h>

@class UserContext;
@class UserContextMembership;

@interface UserContext : JSONModel

extern NSString * const USER_STATUS_ME;

extern NSString * const USER_STATUS_FOLLOWED;
extern NSString * const USER_STATUS_FOLLOWS;
extern NSString * const USER_STATUS_FOLLOW_BOTH;

extern NSString * const USER_STATUS_BLOCKED;
extern NSString * const USER_STATUS_BLOCKS;
extern NSString * const USER_STATUS_BLOCKS_BOTH;

extern NSString * const USER_STATUS_NO_RELATION;

extern NSString * const USER_STATUS_LOADING;

@property (nonatomic) UserContextMembership <Optional> *membership;
@property (nonatomic) NSString *status;

- (void)setStatusWithString:(NSString *)string;

@end

@interface UserContextMembership : JSONModel

@property (nonatomic) NSString *followedAt;
@property (nonatomic) NSString <Optional> *blockedAt;

@end
