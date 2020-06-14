//
//  BFContext.h
//  Pulse
//
//  Created by Austin Valleskey on 6/20/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFJSONModel.h"

NS_ASSUME_NONNULL_BEGIN

@class BFContext;

@class BFContextCamp;
@class BFContextCampMembership;
@class BFContextCampMembershipRole;
@class BFContextCampMembershipSubscription;
@class BFContextCampPermissions;
@class BFContextCampPermissionsMembers;

@class BFContextPost;
@class BFContextPostReplies;
@class BFContextPostPermissions;
@class BFContextPostVote;

@class BFContextMe;
@class BFContextMeFollow;
@class BFContextMeFollowMe;
@class BFContextMeFollowMeSubscription;

@interface BFContext : BFJSONModel

// media types
extern NSString * const BFMediaTypeText; // "text"
extern NSString * const BFMediaTypeLongFormText; // "media/text"
extern NSString * const BFMediaTypeImage; // "media/img"
extern NSString * const BFMediaTypeGIF; // "media/gif"
extern NSString * const BFMediaTypeVideo; // "media/video"

@property (nonatomic) BFContextCamp <Optional> *camp;
@property (nonatomic) BFContextPost <Optional> *post;
@property (nonatomic) BFContextMe <Optional> *me;

@end

// BFContext.camp
@interface BFContextCamp : BFJSONModel

// camp role
extern NSString * const CAMP_ROLE_MEMBER;
extern NSString * const CAMP_ROLE_MODERATOR;
extern NSString * const CAMP_ROLE_ADMIN;

@property (nonatomic) BOOL isFavorite; // derived from "favorite"

@property (nonatomic) BFContextCampMembership <Optional> *membership;

// camp status
extern NSString * const CAMP_STATUS_INVITED;
extern NSString * const CAMP_STATUS_REQUESTED;
extern NSString * const CAMP_STATUS_MEMBER;
extern NSString * const CAMP_STATUS_LEFT;
extern NSString * const CAMP_STATUS_BLOCKED;
extern NSString * const CAMP_STATUS_NO_RELATION;
//
extern NSString * const CAMP_STATUS_LOADING;
@property (nonatomic) NSString <Optional> *status;

extern NSString * const CAMP_WALL_REQUEST;
@property (nonatomic) NSArray <Optional> *walls;

@property (nonatomic) BFContextCampPermissions <Optional> *permissions;

@end

// BFContext.camp.membership
@interface BFContextCampMembership : BFJSONModel

@property (nonatomic) NSString <Optional> *joinedAt;
@property (nonatomic) BFContextCampMembershipRole <Optional> *role;

@property (nonatomic) BFContextCampMembershipSubscription <Optional> * _Nullable subscription;

@end

// BFContext.camp.membership.role
@interface BFContextCampMembershipRole : BFJSONModel

@property (nonatomic) NSString <Optional> *type;
@property (nonatomic) NSString <Optional> *assignedAt;

@end

// BFContext.camp.membership.subscription
@interface BFContextCampMembershipSubscription : BFJSONModel

@property (nonatomic) NSString <Optional> *createdAt;
//@property (nonatomic) NSString <Optional> *level;

@end

// BFContext.camp.permissions
@interface BFContextCampPermissions : BFJSONModel

@property (nonatomic) NSArray <Optional> *post;
@property (nonatomic) NSArray <Optional> *reply;
@property (nonatomic) NSArray <Optional> *assign;
@property (nonatomic) BFContextCampPermissionsMembers <Optional> *members;
@property (nonatomic) BOOL canInvite;
@property (nonatomic) BOOL canUpdate;
@property (nonatomic) BOOL canDelete;

- (BOOL)canPost;
- (BOOL)postContainsMediaType:(NSString *)mediaType;

- (BOOL)canReply;
- (BOOL)replyContainsMediaType:(NSString *)mediaType;

- (BOOL)canPostMedia;
- (BOOL)canReplyMedia;

@end

// BFContext.camp.permissions.members
@interface BFContextCampPermissionsMembers : BFJSONModel

// can they invite new members
@property (nonatomic) BOOL invite;

// can they accept/decline member requests in a private camp
@property (nonatomic) BOOL approve;

@end

// BFContext.post
@interface BFContextPost : BFJSONModel

@property (nonatomic) BFContextPostReplies <Optional> *replies;
@property (nonatomic) BFContextPostPermissions <Optional> *permissions;
@property (nonatomic) BFContextPostVote <Optional> * _Nullable vote;
@property (nonatomic) BOOL muted;

@end

// BFContext.post.replies
@interface BFContextPostReplies : BFJSONModel

@property (nonatomic) NSInteger count;

@end

// BFContext.post.permissions
@interface BFContextPostPermissions : BFJSONModel

@property (nonatomic) NSArray <Optional> *reply;
@property (nonatomic) BOOL canDelete;

- (BOOL)canReply;
- (BOOL)replyContainsMediaType:(NSString *)mediaType;

@end

// BFContext.post.vote
@interface BFContextPostVote : BFJSONModel

@property (nonatomic) NSString *createdAt;

@end

// BFContext.me
@interface BFContextMe : BFJSONModel

@property (nonatomic) BFContextMeFollow <Optional> *follow;

extern NSString * const USER_STATUS_ME;
//
extern NSString * const USER_STATUS_FOLLOWED;
extern NSString * const USER_STATUS_FOLLOWS;
extern NSString * const USER_STATUS_FOLLOW_BOTH;
//
extern NSString * const USER_STATUS_BLOCKED;
extern NSString * const USER_STATUS_BLOCKS;
extern NSString * const USER_STATUS_BLOCKS_BOTH;
//
extern NSString * const USER_STATUS_NO_RELATION;
//
extern NSString * const USER_STATUS_LOADING;
@property (nonatomic) NSString *status;

@end

@interface BFContextMeFollow : BFJSONModel

@property (nonatomic) BFContextMeFollowMe <Optional> *me;

@end

@interface BFContextMeFollowMe : BFJSONModel

@property (nonatomic) NSString <Optional> *createdAt;
@property (nonatomic) BFContextMeFollowMeSubscription <Optional> * _Nullable subscription;

@end

@interface BFContextMeFollowMeSubscription : BFJSONModel

@property (nonatomic) NSString <Optional> *createdAt;

@end

NS_ASSUME_NONNULL_END
