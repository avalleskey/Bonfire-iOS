#import "Camp.h"
#import "HAWebService.h"
@import Firebase;

@implementation Camp

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return TRUE;
}
+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                                                                  @"identifier": @"id"
                                                                  }];
}

- (NSString *)campIdentifier {
    if (self.identifier != nil) return self.identifier;
    if (self.attributes.identifier != nil) return self.attributes.identifier;
    
    return nil;
}

#pragma mark - Helper methods
- (BOOL)isVerified {
    return self.attributes.isVerified;
}
- (BOOL)isChannel {
    return [self.attributes.display.format isEqualToString:CAMP_DISPLAY_FORMAT_CHANNEL];
}
- (BOOL)isPrivate {
    return [self.attributes isPrivate];
}

#pragma mark - API Methods
- (void)subscribeToCamp  {
    [FIRAnalytics logEventWithName:@"subscribe_to_camp" parameters:@{}];
    
    // Update the object
    BFContextCampMembershipSubscription *subscription = [[BFContextCampMembershipSubscription alloc] init];
    NSDate *date = [NSDate new];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    subscription.createdAt = [dateFormatter stringFromDate:date];
    self.attributes.context.camp.membership.subscription = subscription;
    
    NSString *url = [NSString stringWithFormat:@"camps/%@/members/subscriptions", [self campIdentifier]];
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] POST:url parameters:@{@"vendor": @"APNS", @"token": [[NSUserDefaults standardUserDefaults] stringForKey:@"device_token"]} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CampUpdated" object:self];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
    }];
}
- (void)unsubscribeFromCamp {
    [FIRAnalytics logEventWithName:@"unsubscribe_from_camp" parameters:@{}];
    
    // Update the object
    self.attributes.context.camp.membership.subscription = nil;
    
    NSString *url = [NSString stringWithFormat:@"camps/%@/members/subscriptions", [self campIdentifier]];
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] DELETE:url parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CampUpdated" object:self];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
    }];
}
- (void)report {
    [FIRAnalytics logEventWithName:@"camp_report"
                            parameters:@{}];
        
    NSString *url = [NSString stringWithFormat:@"camps/%@/report", self.identifier];
    
    [[HAWebService authenticatedManager] POST:url parameters:@{} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
    } failure:nil];
}

@end

@implementation NSArray (CampArray)

- (NSArray <Camp *> *)toCampArray {
    NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithArray:self];
    [mutableArray enumerateObjectsUsingBlock:^(NSDictionary *object, NSUInteger idx, BOOL *stop) {
        if ([object isKindOfClass:[NSDictionary class]]) {
            [mutableArray replaceObjectAtIndex:idx withObject:[[Camp alloc] initWithDictionary:object error:nil]];
        }
    }];
    
    return [mutableArray copy];
}
- (NSArray <NSDictionary *> *)toCampDictionaryArray {
    NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithArray:self];
    [mutableArray enumerateObjectsUsingBlock:^(Camp *object, NSUInteger idx, BOOL *stop) {
        if ([object isKindOfClass:[Camp class]]) {
            [mutableArray replaceObjectAtIndex:idx withObject:[object toDictionary]];
        }
    }];
    
    return [mutableArray copy];
}

@end
