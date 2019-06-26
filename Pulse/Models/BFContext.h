//
//  BFContext.h
//  Pulse
//
//  Created by Austin Valleskey on 6/20/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "JSONModel.h"

NS_ASSUME_NONNULL_BEGIN

@class BFContext;

@class BFContextCamp;
@class BFContextCampMembership;
@class BFContextCampMembershipRole;
@class BFContextCampMembershipSubscription;
@class BFContextCampPermissions;

@class BFContextPost;
@class BFContextPostReplies;
@class BFContextPostPermissions;
@class BFContextPostVote;

@class BFContextMe;
@class BFContextMeFollow;
@class BFContextMeFollowMe;
@class BFContextMeFollowMeSubscription;

@interface BFContext : JSONModel

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
@interface BFContextCamp : JSONModel

// camp status
extern NSString * const CAMP_STATUS_INVITED;
extern NSString * const CAMP_STATUS_REQUESTED;
extern NSString * const CAMP_STATUS_MEMBER;
extern NSString * const CAMP_STATUS_LEFT;
extern NSString * const CAMP_STATUS_BLOCKED;
extern NSString * const CAMP_STATUS_NO_RELATION;

extern NSString * const CAMP_STATUS_CAMP_BLOCKED;
extern NSString * const CAMP_STATUS_LOADING;

// camp role
extern NSString * const CAMP_ROLE_MEMBER;
extern NSString * const CAMP_ROLE_MODERATOR;
extern NSString * const CAMP_ROLE_ADMIN;

@property (nonatomic) BFContextCampMembership <Optional> *membership;

@property (nonatomic) NSString <Optional> *status;
- (void)setStatusWithString:(NSString *)string;

@property (nonatomic) BFContextCampPermissions <Optional> *permissions;

@end

// BFContext.camp.membership
@interface BFContextCampMembership : JSONModel

@property (nonatomic) NSString <Optional> *joinedAt;
@property (nonatomic) NSString <Optional> *blockedAt;
@property (nonatomic) BFContextCampMembershipRole <Optional> *role;
@property (nonatomic) BFContextCampMembershipSubscription <Optional> * _Nullable subscription;

@end

// BFContext.camp.membership.role
@interface BFContextCampMembershipRole : JSONModel

@property (nonatomic) NSString <Optional> *type;
@property (nonatomic) NSString <Optional> *assignedAt;

@end

// BFContext.camp.membership.subscription
@interface BFContextCampMembershipSubscription : JSONModel

@property (nonatomic) NSString <Optional> *createdAt;

@end

// BFContext.camp.permissions
@interface BFContextCampPermissions : JSONModel

@property (nonatomic) NSArray <Optional> *post;
@property (nonatomic) NSArray <Optional> *reply;
@property (nonatomic) NSArray <Optional> *assign;
@property (nonatomic) BOOL canInvite;
@property (nonatomic) BOOL canUpdate;
@property (nonatomic) BOOL canDelete;

- (BOOL)canPost;
- (BOOL)postContainsMediaType:(NSString *)mediaType;

- (BOOL)canReply;
- (BOOL)replyContainsMediaType:(NSString *)mediaType;

@end


// BFContext.post
@interface BFContextPost : JSONModel

@property (nonatomic) BFContextPostReplies <Optional> *replies;
@property (nonatomic) BFContextPostPermissions <Optional> *permissions;
@property (nonatomic) BFContextPostVote <Optional> * _Nullable vote;

@end

// BFContext.post.replies
@interface BFContextPostReplies : JSONModel

@property (nonatomic) NSInteger count;

@end

// BFContext.post.permissions
@interface BFContextPostPermissions : JSONModel

@property (nonatomic) NSArray <Optional> *reply;
@property (nonatomic) BOOL canDelete;

- (BOOL)canReply;
- (BOOL)replyContainsMediaType:(NSString *)mediaType;

@end

// BFContext.post.vote
@interface BFContextPostVote : JSONModel

@property (nonatomic) NSString *createdAt;

@end

// BFContext.me
@interface BFContextMe : JSONModel

extern NSString * const USER_STATUS_ME;

extern NSString * const USER_STATUS_FOLLOWED;
extern NSString * const USER_STATUS_FOLLOWS;
extern NSString * const USER_STATUS_FOLLOW_BOTH;

extern NSString * const USER_STATUS_BLOCKED;
extern NSString * const USER_STATUS_BLOCKS;
extern NSString * const USER_STATUS_BLOCKS_BOTH;

extern NSString * const USER_STATUS_NO_RELATION;

extern NSString * const USER_STATUS_LOADING;

@property (nonatomic) BFContextMeFollow <Optional> *follow;
@property (nonatomic) NSString *status;

- (void)setStatusWithString:(NSString *)string;

@end

@interface BFContextMeFollow : JSONModel

@property (nonatomic) BFContextMeFollowMe <Optional> *me;

@end

@interface BFContextMeFollowMe : JSONModel

@property (nonatomic) NSString <Optional> *createdAt;
@property (nonatomic) BFContextMeFollowMeSubscription <Optional> * _Nullable subscription;

@end

@interface BFContextMeFollowMeSubscription : JSONModel

@property (nonatomic) NSString <Optional> *createdAt;

@end

NS_ASSUME_NONNULL_END
