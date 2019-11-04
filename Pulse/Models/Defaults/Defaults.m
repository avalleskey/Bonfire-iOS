//
//  Defaults.m
//  Pulse
//
//  Created by Austin Valleskey on 10/17/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "Defaults.h"

@implementation Defaults

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return TRUE;
}

@end

@implementation DefaultsKeywords

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return TRUE;
}

@end

@implementation DefaultsKeywordsViewTitles

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return TRUE;
}

@end

@implementation DefaultsPost

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return TRUE;
}

@end

@implementation DefaultsPostImgHeight

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return TRUE;
}

@end

@implementation DefaultsCamp

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return TRUE;
}

@end

@implementation DefaultsFeed

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}
+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return TRUE;
}

@end

@implementation DefaultsFeedMotd

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}
+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return TRUE;
}

@end

@implementation DefaultsFeedMotdCta

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}
+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return TRUE;
}

@end

@implementation DefaultsLogging

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return TRUE;
}

@end

@implementation DefaultsLoggingInsights

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return TRUE;
}

@end

@implementation DefaultsLoggingInsightsImpressions

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return TRUE;
}

@end

@implementation DefaultsLoggingInsightsImpressionsBatching

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return TRUE;
}

@end

@implementation DefaultsNotificationsFormat

NSString * const ACTIVITY_ACTION_OBJECT_ACTIONER = @"actioner";
NSString * const ACTIVITY_ACTION_OBJECT_POST = @"post";
NSString * const ACTIVITY_ACTION_OBJECT_REPLY_POST = @"reply_post";
NSString * const ACTIVITY_ACTION_OBJECT_CAMP = @"camp";

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return TRUE;
}

@end
