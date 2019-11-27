//
//  Identity.m
//  Pulse
//
//  Created by Austin Valleskey on 11/5/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "Identity.h"
#import "GTMNSString+HTML.h"
#import "Bot.h"
#import "User.h"
#import "HAWebService.h"
@import Firebase;

@implementation Identity

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                                                                  @"identifier": @"id"
                                                                  }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return true;
}

#pragma mark - Helper methods
- (BOOL)isVerified {
    return [self.attributes isVerified];
}

- (void)report {
    [FIRAnalytics logEventWithName:@"user_report"
                            parameters:@{}];
        
    NSString *url = [NSString stringWithFormat:@"users/%@/report", self.identifier];
    
    [[HAWebService authenticatedManager] POST:url parameters:@{} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
    } failure:nil];
}

@end

@implementation IdentityAttributes

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                                                                  @"displayName": @"display_name",
                                                                  @"createdAt": @"created_at",
                                                                  @"isSuspended": @"is_suspended",
                                                                  @"isVerified": @"verified",
                                                                  @"theDescription": @"description"
                                                                  }];
}

- (void)setDisplayNameWithNSString:(NSString *)string {
    self.displayName = [string gtm_stringByUnescapingFromHTML];
}
- (void)setBioWithNSString:(NSString *)string {
    self.bio = [string gtm_stringByUnescapingFromHTML];
}
- (void)setTheDescriptionWithNSString:(NSString *)string {
    self.theDescription = [string gtm_stringByUnescapingFromHTML];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return true;
}

@end

@implementation IdentityAttributesWebsite

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                                                                  @"displayUrl": @"display_url",
                                                                  @"actionUrl": @"action_url"
                                                                  }];
}

@end

@implementation IdentityMedia

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return true;
}

@end

@implementation IdentitySummaries

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return true;
}

@end

@implementation IdentitySummariesCounts

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return true;
}

@end
