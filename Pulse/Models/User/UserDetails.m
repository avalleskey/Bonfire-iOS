#import "UserDetails.h"
#import "GTMNSString+HTML.h"

@implementation UserDetails

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
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

@end

@implementation UserDetailsLocation

- (void)setValue:(NSString<Optional> *)value {
    if (value != _value) {
        _value = [value gtm_stringByUnescapingFromHTML];
    }
}

@end

@implementation UserDetailsWebsite

@end
