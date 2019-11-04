#import "BotMedia.h"

@implementation BotMedia

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

@end

