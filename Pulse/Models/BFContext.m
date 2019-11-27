//
//  BFContext.m
//  Pulse
//
//  Created by Austin Valleskey on 6/20/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFContext.h"

@implementation BFContext

// Media types
NSString * const BFMediaTypeText = @"text";
NSString * const BFMediaTypeLongFormText = @"media/text";
NSString * const BFMediaTypeImage = @"media/img";
NSString * const BFMediaTypeGIF = @"media/gif";
NSString * const BFMediaTypeVideo = @"media/video";

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

@end

@implementation BFContextCamp

// camp status
NSString * const CAMP_STATUS_INVITED = @"invited";
NSString * const CAMP_STATUS_REQUESTED = @"requested";
NSString * const CAMP_STATUS_MEMBER = @"member";
NSString * const CAMP_STATUS_LEFT = @"left";
NSString * const CAMP_STATUS_BLOCKED = @"blocked";
NSString * const CAMP_STATUS_NO_RELATION = @"none";
//
NSString * const CAMP_STATUS_LOADING = @"loading";

// camp role
NSString * const CAMP_ROLE_MEMBER = @"member";
NSString * const CAMP_ROLE_MODERATOR = @"moderator";
NSString * const CAMP_ROLE_ADMIN = @"admin";

- (void)setStatusWithString:(NSString *)string {
    if (![string isEqualToString:_status]) {
        _status = string;
    }
}

@end

@implementation BFContextCampMembership

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return true;
}

@end

@implementation BFContextCampMembershipRole

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

@end

@implementation BFContextCampMembershipSubscription

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

@end

@implementation BFContextCampPermissions

+ (BOOL)propertyIsOptional:(NSString*)propertyName
{
    return YES; // all are optional
}

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                                                                  @"canInvite": @"invite",
                                                                  @"canUpdate": @"update",
                                                                  @"canDelete": @"delete"
                                                                  }];
}

- (BOOL)canPost {
    NSArray *availableMediaTypes = @[BFMediaTypeText, BFMediaTypeImage, BFMediaTypeGIF, BFMediaTypeVideo];
    for (NSString *mediaType in availableMediaTypes) {
        if ([self postContainsMediaType:mediaType]) {
            return true;
        }
    }
    
    return false;
}
- (BOOL)canReply {
    NSArray *availableMediaTypes = @[BFMediaTypeText, BFMediaTypeImage, BFMediaTypeGIF, BFMediaTypeVideo];
    for (NSString *mediaType in availableMediaTypes) {
        if ([self replyContainsMediaType:mediaType]) {
            return true;
        }
    }
    
    return false;
}

- (BOOL)canPostMedia {
    NSArray *mediaTypes = @[BFMediaTypeImage, BFMediaTypeGIF];
    for (NSString *mediaType in mediaTypes) {
        if ([self postContainsMediaType:mediaType]) {
            return true;
        }
    }
    
    return false;
}
- (BOOL)canReplyMedia {
    NSArray *mediaTypes = @[BFMediaTypeImage, BFMediaTypeGIF];
    for (NSString *mediaType in mediaTypes) {
        if ([self replyContainsMediaType:mediaType]) {
            return true;
        }
    }
    
    return false;
}

- (BOOL)postContainsMediaType:(NSString *)mediaType {
    return [self.post containsObject:mediaType];
}
- (BOOL)replyContainsMediaType:(NSString *)mediaType {
    return [self.reply containsObject:mediaType];
}

@end

@implementation BFContextCampPermissionsMembers

+ (BOOL)propertyIsOptional:(NSString*)propertyName
{
    return YES; // all are optional
}

@end

@implementation BFContextPost

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

@end

@implementation BFContextPostReplies

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

@end

@implementation BFContextPostPermissions

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                                                                  @"canDelete": @"delete"
                                                                  }];
}

- (BOOL)canReply {    
    NSArray *availableMediaTypes = @[BFMediaTypeText, BFMediaTypeLongFormText, BFMediaTypeImage, BFMediaTypeGIF, BFMediaTypeVideo];
    for (NSString *mediaType in availableMediaTypes) {
        if ([self replyContainsMediaType:mediaType]) {
            return true;
        }
    }
    
    return false;
}
- (BOOL)replyContainsMediaType:(NSString *)mediaType {
    return [self.reply containsObject:mediaType];
}

@end

@implementation BFContextPostVote

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

@end

@implementation BFContextMe

NSString * const USER_STATUS_ME = @"me";

NSString * const USER_STATUS_FOLLOWED = @"follows_me";
NSString * const USER_STATUS_FOLLOWS = @"follows_them";
NSString * const USER_STATUS_FOLLOW_BOTH = @"follows_both";

NSString * const USER_STATUS_BLOCKED = @"blocks_me";
NSString * const USER_STATUS_BLOCKS = @"blocks_them";
NSString * const USER_STATUS_BLOCKS_BOTH = @"blocks_both";

NSString * const USER_STATUS_NO_RELATION = @"none";

NSString * const USER_STATUS_LOADING = @"loading";

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

- (void)setStatusWithString:(NSString *)string {
    self.status = string;
}

@end

@implementation BFContextMeFollow

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

@end

@implementation BFContextMeFollowMe

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

@end

@implementation BFContextMeFollowMeSubscription

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

@end
