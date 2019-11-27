//
//  UserActivity.h
//  Pulse
//
//  Created by Austin Valleskey on 3/8/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFJSONModel.h"
#import "User.h"
#import "Camp.h"
#import "Post.h"

NS_ASSUME_NONNULL_BEGIN

@class UserActivity;
@class UserActivityAttributes;

@interface UserActivity : BFJSONModel

@property (nonatomic) NSString <Optional> *identifier;
@property (nonatomic) NSString <Optional> *type;
@property (nonatomic) UserActivityAttributes <Optional> *attributes;

@property (nonatomic) NSString <Optional> *prevCursor;
@property (nonatomic) NSString <Optional> *nextCursor;

- (void)markAsRead;

@end

@interface UserActivityAttributes : BFJSONModel

typedef enum {
    USER_ACTIVITY_TYPE_UNKNOWN = 0,
    
    // Result of a user action
    USER_ACTIVITY_TYPE_USER_FOLLOW = 1,
    USER_ACTIVITY_TYPE_USER_ACCEPTED_ACCESS = 2,
    USER_ACTIVITY_TYPE_USER_POSTED = 6,
    USER_ACTIVITY_TYPE_USER_POSTED_CAMP = 9,
    
    // Result of an action in a joined camp
    USER_ACTIVITY_TYPE_CAMP_ACCESS_REQUEST = 3,
    USER_ACTIVITY_TYPE_CAMP_INVITE = 7,
    
    // Result of action on user's post
    USER_ACTIVITY_TYPE_POST_REPLY = 4,
    USER_ACTIVITY_TYPE_POST_VOTED = 5,
    USER_ACTIVITY_TYPE_POST_MENTION = 8
} USER_ACTIVITY_TYPE;

@property (nonatomic) USER_ACTIVITY_TYPE type;
@property (nonatomic) NSString <Optional> *createdAt;

@property (nonatomic) User <Optional> *actioner;

@property (nonatomic) Post <Optional> *post;
@property (nonatomic) Post <Optional> *replyPost;

@property (nonatomic) Camp <Optional> *camp;

@property (nonatomic) BOOL read;

// the NSAttributed string we create, using the JSON defaults format and information given to use during initWithDictionary
@property (nonatomic) NSAttributedString <Optional> *attributedString;

@end

@interface JSONValueTransformer (NSAttributedString)
@end

NS_ASSUME_NONNULL_END
