#import "UserDetails.h"

@implementation UserDetails

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

@end

@implementation UserDetailsLocation

@end

@implementation UserDetailsWebsite

@end
