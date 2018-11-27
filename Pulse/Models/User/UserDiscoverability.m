#import "UserDiscoverability.h"

@implementation UserDiscoverability

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

@end
