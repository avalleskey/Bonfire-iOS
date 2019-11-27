//
//  Defaults.m
//  Pulse
//
//  Created by Austin Valleskey on 10/17/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "Defaults.h"
#import "HAWebService.h"

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

@implementation DefaultsAnnouncement

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"identifier": @"id"
                                                                  }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return TRUE;
}

- (void)dismissWithCompletion:(void (^_Nullable)(BOOL success, id __nullable responseObject))completion {
    NSString *url = [NSString stringWithFormat:@"clients/announcements/%@", self.identifier];
    [[HAWebService authenticatedManager] DELETE:url parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  __nullable responseObject) {
        if (completion) {
            completion(true, @{@"dismissed": @true});
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completion) {
            completion(false, @{});
        }
    }];
}

- (void)ctaTappedWithCompletion:(void (^_Nullable)(BOOL success, id __nullable responseObject))completion {
    NSString *url = [NSString stringWithFormat:@"clients/announcements/%@", self.identifier];
    [[HAWebService authenticatedManager] POST:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  __nullable responseObject) {
        if (completion) {
            completion(true, @{@"cta_tapped": @true});
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completion) {
            completion(false, @{});
        }
    }];
}

@end

@implementation DefaultsAnnouncementAttributes

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}
+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return TRUE;
}

@end

@implementation DefaultsAnnouncementAttributesCta

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
