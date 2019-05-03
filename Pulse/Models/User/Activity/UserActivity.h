//
//  UserActivity.h
//  Pulse
//
//  Created by Austin Valleskey on 3/8/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "JSONModel.h"
#import "User.h"
#import "Room.h"
#import "Post.h"

NS_ASSUME_NONNULL_BEGIN

@class UserActivity;
@class UserActivityAttributes;
@class UserActivityDetails;
@class UserActivityStatus;

@interface UserActivity : JSONModel

extern NSString * const USER_ACTIVITY_TYPE_USER_FOLLOW;
extern NSString * const USER_ACTIVITY_TYPE_USER_ACCEPTED_ACCESS;
extern NSString * const USER_ACTIVITY_TYPE_ROOM_ACCESS_REQUEST;
extern NSString * const USER_ACTIVITY_TYPE_POST_REPLY;
extern NSString * const USER_ACTIVITY_TYPE_POST_SPARKED;
extern NSString * const USER_ACTIVITY_TYPE_USER_POSTED;

@property (nonatomic) NSString <Optional> *identifier;
@property (nonatomic) NSString <Optional> *type;
@property (nonatomic) UserActivityAttributes <Optional> *attributes;

@end

@interface UserActivityAttributes : JSONModel

@property (nonatomic) UserActivityDetails <Optional> *details;
@property (nonatomic) UserActivityStatus <Optional> *status;

@end

@interface UserActivityDetails : JSONModel

@property (nonatomic) User <Optional> *actionedBy;

@property (nonatomic) Post <Optional> *post;
@property (nonatomic) Post <Optional> *replyPost;

@property (nonatomic) Room <Optional> *room;

@end

@interface UserActivityStatus : JSONModel

@property (nonatomic) NSString *createdAt;

@end

NS_ASSUME_NONNULL_END
