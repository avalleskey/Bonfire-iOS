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
#import "Session.h"

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
- (BOOL)isBetaTester {
    if (self.attributes.createdAt.length == 0) return false;
    
    NSDateFormatter *gmtDateFormatter = [[NSDateFormatter alloc] init];
    gmtDateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    gmtDateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
    NSDate *date = [gmtDateFormatter dateFromString:self.attributes.createdAt];
    
    return [date compare:[gmtDateFormatter dateFromString:@"2020-04-17T00:00:00Z"]] == NSOrderedAscending;
}
- (BOOL)isBot {
    return ([self.type isEqualToString:@"bot"]);
}
- (BOOL)isCurrentIdentity {
    if (!self.identifier && !self.attributes.identifier) {
        return NO;
    }
    
    User *currentUser = [Session sharedInstance].currentUser;
    
    return ([self.attributes.identifier isEqualToString:currentUser.attributes.identifier] || [self.identifier isEqualToString:currentUser.identifier]);
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
                                                                  @"theDescription": @"description",
                                                                  @"requiresInvite": @"requires_invite"
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
