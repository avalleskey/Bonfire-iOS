//
//  RoomContext.m
//  Pulse
//
//  Created by Austin Valleskey on 10/21/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "RoomContext.h"

@implementation RoomContext

NSString * const ROOM_STATUS_INVITED = @"invited";
NSString * const ROOM_STATUS_REQUESTED = @"requested";
NSString * const ROOM_STATUS_MEMBER = @"member";
NSString * const ROOM_STATUS_LEFT = @"left";
NSString * const ROOM_STATUS_BLOCKED = @"blocked";
NSString * const ROOM_STATUS_NO_RELATION = @"none";

NSString * const ROOM_STATUS_ROOM_BLOCKED = @"room_blocked";
NSString * const ROOM_STATUS_LOADING = @"loading";

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

- (void)setStatusWithString:(NSString *)string {
    if (string != _status) {
        _status = string;
    }
}

@end

@implementation RoomContextInvite

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

@end

@implementation RoomContextMembership

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

@end

@implementation RoomContextMembershipRole

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                                                                  @"identifier": @"id",
                                                                  @"assignedAt": @"assigned_at"
                                                                  }];
}

@end

@implementation RoomContextMembershipSubscription

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

@end

@implementation RoomContextPermissions

NSString * const BFMediaTypeText = @"text";
NSString * const BFMediaTypeLongFormText = @"media/text";
NSString * const BFMediaTypeImage = @"media/img";
NSString * const BFMediaTypeGIF = @"media/gif";
NSString * const BFMediaTypeVideo = @"media/video";

+ (BOOL)propertyIsOptional:(NSString*)propertyName
{
    return YES; // all are optional
}

- (BOOL)canPost {
    return true;
    
    if (self.post == nil || self.post.count == 0) {
        return true;
    }
    
    NSArray *availableMediaTypes = @[BFMediaTypeText, BFMediaTypeLongFormText, BFMediaTypeImage, BFMediaTypeGIF, BFMediaTypeVideo];
    for (NSString *mediaType in availableMediaTypes) {
        if ([self postContainsMediaType:mediaType]) {
            return true;
        }
    }
    
    return false;
}
- (BOOL)canReply {
    return true;
    
    if (self.reply == nil || self.reply.count == 0) {
        return true;
    }
    
    NSArray *availableMediaTypes = @[BFMediaTypeText, BFMediaTypeLongFormText, BFMediaTypeImage, BFMediaTypeGIF, BFMediaTypeVideo];
    for (NSString *mediaType in availableMediaTypes) {
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
    return [self.post containsObject:mediaType];
}

@end
