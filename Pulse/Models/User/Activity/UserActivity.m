//
//  UserActivity.m
//  Pulse
//
//  Created by Austin Valleskey on 3/8/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "UserActivity.h"

@implementation UserActivity

NSString * const USER_ACTIVITY_TYPE_USER_FOLLOW = @"TYPE_USER_FOLLOW";
NSString * const USER_ACTIVITY_TYPE_USER_ACCEPTED_ACCESS = @"TYPE_USER_ACCEPTED_ACCESS";
NSString * const USER_ACTIVITY_TYPE_ROOM_ACCESS_REQUEST = @"TYPE_ROOM_ACCESS_REQUEST";
NSString * const USER_ACTIVITY_TYPE_POST_REPLY = @"TYPE_POST_REPLY";
NSString * const USER_ACTIVITY_TYPE_POST_SPARKED = @"TYPE_POST_SPARKED";
NSString * const USER_ACTIVITY_TYPE_USER_POSTED = @"TYPE_USER_POSTED";

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                                                                  @"identifier": @"id"
                                                                  }];
}

@end

@implementation UserActivityAttributes

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

@end

@implementation UserActivityDetails

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

@end

@implementation UserActivityStatus

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

@end
