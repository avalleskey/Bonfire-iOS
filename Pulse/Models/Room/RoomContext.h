//
//  RoomContext.h
//  Pulse
//
//  Created by Austin Valleskey on 10/21/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "JSONModel.h"
#import "User.h"

@class RoomContext;
@class RoomContextInvite;
@class RoomContextMembership;
@class RoomContextMembershipRole;
@class RoomContextMembershipSubscription;

@interface RoomContext : JSONModel

extern NSString * const ROOM_STATUS_INVITED;
extern NSString * const ROOM_STATUS_REQUESTED;
extern NSString * const ROOM_STATUS_MEMBER;
extern NSString * const ROOM_STATUS_LEFT;
extern NSString * const ROOM_STATUS_BLOCKED;
extern NSString * const ROOM_STATUS_NO_RELATION;

extern NSString * const ROOM_STATUS_ROOM_BLOCKED;
extern NSString * const ROOM_STATUS_LOADING;

@property (nonatomic) RoomContextInvite <Optional> *invite;
@property (nonatomic) RoomContextMembership <Optional> *membership;
@property (nonatomic) NSString <Optional> *status;

- (void)setStatusWithString:(NSString *)string;

@end

@interface RoomContextInvite : JSONModel

@property (nonatomic) User *createdBy;
@property (nonatomic) NSString *createdAt;

@end

@interface RoomContextMembership : JSONModel

@property (nonatomic) NSString <Optional> *joinedAt;
@property (nonatomic) NSString <Optional> *blockedAt;
@property (nonatomic) RoomContextMembershipRole <Optional> *role;
@property (nonatomic) RoomContextMembershipSubscription <Optional> *subscription;

@end

@interface RoomContextMembershipRole : JSONModel

typedef enum {
    ROOM_ROLE_MEMBER = 0,
    ROOM_ROLE_ADMIN = 1
} ROOM_ROLE;

@property (nonatomic) ROOM_ROLE identifier;
@property (nonatomic) NSString *assignedAt;

@end

@interface RoomContextMembershipSubscription : JSONModel

@property (nonatomic) NSString *createdAt;

@end
