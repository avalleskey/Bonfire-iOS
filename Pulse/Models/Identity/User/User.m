#import "User.h"
#import "GTMNSString+HTML.h"
#import "HAWebService.h"
@import Firebase;

@implementation User

#pragma mark - API Methods
- (void)subscribeToPostNotifications {
    [FIRAnalytics logEventWithName:@"subscribe_to_user"
                        parameters:@{}];
    
    // Update the object
    NSDate *date = [NSDate new];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *created_at = [dateFormatter stringFromDate:date];
    BFContextMeFollowMeSubscription *subscription = [[BFContextMeFollowMeSubscription alloc] initWithDictionary:@{@"created_at": created_at} error:nil];
    self.attributes.context.me.follow.me.subscription = subscription;
    
    NSString *url = [NSString stringWithFormat:@"users/%@/notifications/subscription", self.identifier];
    
    [[HAWebService authenticatedManager] POST:url parameters:@{@"vendor": @"APNS", @"token": [[NSUserDefaults standardUserDefaults] stringForKey:@"device_token"]} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UserUpdated" object:self];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
    }];
}
- (void)unsubscribeFromPostNotifications {
    [FIRAnalytics logEventWithName:@"unsubscribe_from_user"
                        parameters:@{}];
    
    // Update the object
    self.attributes.context.me.follow.me.subscription = nil;
    
    NSString *url = [NSString stringWithFormat:@"users/%@/notifications/subscription", self.identifier];
    
    [[HAWebService authenticatedManager] DELETE:url parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UserUpdated" object:self];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
    }];
}

@end

@implementation UserDetailsLocation

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

- (void)setDisplayTextWithNSString:(NSString *)string {
    self.displayText = [string gtm_stringByUnescapingFromHTML];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return true;
}

@end
