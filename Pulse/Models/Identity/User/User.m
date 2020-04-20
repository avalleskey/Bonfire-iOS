#import "User.h"
#import "GTMNSString+HTML.h"
#import "HAWebService.h"
@import Firebase;

@implementation User

- (id)init {
    if (self = [super init]) {
        self.type = @"user";
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError **)err {
    User *instance = [super initWithDictionary:dict error:err];
    
//    instance.attributes.media.cover = [[BFHostedVersions alloc] initWithDictionary:@{@"full": @{@"url": @"https://cdn.dribbble.com/users/59947/screenshots/7141217/media/1fd099baf2d926d844ca48f837283484.jpg"}} error:nil];
    
    return instance;
}

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

- (BOOL)isBirthday {
    if (self.attributes.dob.length == 0 || [self.attributes.dob componentsSeparatedByString:@"-"].count != 3) return false;
    
    NSDateFormatter *todayFormatter = [[NSDateFormatter alloc] init];
    [todayFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString *todayString = [todayFormatter stringFromDate:[NSDate date]];
    
    NSInteger todayMonth = [[todayString componentsSeparatedByString:@"-"][1] integerValue];
    NSInteger todayDay = [[todayString componentsSeparatedByString:@"-"][2] integerValue];
    
    NSInteger birthdayMonth = [[self.attributes.dob componentsSeparatedByString:@"-"][1] integerValue];
    NSInteger birthdayDay = [[self.attributes.dob componentsSeparatedByString:@"-"][2] integerValue];
    
    return todayMonth == birthdayMonth && todayDay == birthdayDay;
}

@end

@implementation UserAttributesInvites

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return true;
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
