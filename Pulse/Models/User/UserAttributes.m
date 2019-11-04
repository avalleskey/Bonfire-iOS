#import "UserAttributes.h"
#import "GTMNSString+HTML.h"

@implementation UserAttributes

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                                                                  @"displayName": @"display_name",
                                                                  @"isSuspended": @"private",
                                                                  @"isVerified": @"verified",
                                                                  @"createdAt": @"created_at"
                                                                  }];
}

- (void)setDisplayName:(NSString<Optional> *)displayName {
    if (displayName != _displayName) {
        _displayName = [displayName gtm_stringByUnescapingFromHTML];
    }
}

- (void)setBio:(NSString<Optional> *)bio {
    if (bio != _bio) {
        _bio = [bio gtm_stringByUnescapingFromHTML];
    }
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

- (void)setDisplayText:(NSString<Optional> *)displayText {
    if (displayText != _displayText) {
        _displayText = [displayText gtm_stringByUnescapingFromHTML];
    }
}

@end

@implementation UserDetailsWebsite

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

@end
