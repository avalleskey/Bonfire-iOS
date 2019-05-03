//
//  RoomContext.h
//  Pulse
//
//  Created by Austin Valleskey on 10/21/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "JSONModel.h"
#import "User.h"

NS_ASSUME_NONNULL_BEGIN

@class RoomContext;
@class RoomContextInvite;
@class RoomContextMembership;
@class RoomContextMembershipRole;
@class RoomContextMembershipSubscription;
@class RoomContextPermissions;

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
@property (nonatomic) RoomContextPermissions <Optional> *permissions;

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
@property (nonatomic) RoomContextMembershipSubscription <Optional> * _Nullable subscription;

@end

@interface RoomContextMembershipRole : JSONModel

typedef enum {
    ROOM_ROLE_MEMBER = 0,
    ROOM_ROLE_MODERATOR = 1,
    ROOM_ROLE_ADMIN = 2
} ROOM_ROLE;

@property (nonatomic) ROOM_ROLE identifier;
@property (nonatomic) NSString <Optional> *assignedAt;

@end

@interface RoomContextMembershipSubscription : JSONModel

@property (nonatomic) NSString <Optional> *createdAt;

@end

@interface RoomContextPermissions : JSONModel

extern NSString * const BFMediaTypeText; // "text"
extern NSString * const BFMediaTypeLongFormText; // "media/text"
extern NSString * const BFMediaTypeImage; // "media/img"
extern NSString * const BFMediaTypeGIF; // "media/gif"
extern NSString * const BFMediaTypeVideo; // "media/video"

@property (nonatomic) NSArray <Optional> *post;
@property (nonatomic) NSArray <Optional> *reply;
@property (nonatomic) BOOL invite;

- (BOOL)canPost;
- (BOOL)postContainsMediaType:(NSString *)mediaType;

- (BOOL)canReply;
- (BOOL)replyContainsMediaType:(NSString *)mediaType;

@end

NS_ASSUME_NONNULL_END
