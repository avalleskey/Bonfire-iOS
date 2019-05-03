#import "UserContext.h"

@implementation UserContext

NSString * const USER_STATUS_ME = @"me";

NSString * const USER_STATUS_FOLLOWED = @"follows_me";
NSString * const USER_STATUS_FOLLOWS = @"follows_them";
NSString * const USER_STATUS_FOLLOW_BOTH = @"follows_both";

NSString * const USER_STATUS_BLOCKED = @"blocks_me";
NSString * const USER_STATUS_BLOCKS = @"blocks_them";
NSString * const USER_STATUS_BLOCKS_BOTH = @"blocks_both";

NSString * const USER_STATUS_NO_RELATION = @"none";

NSString * const USER_STATUS_LOADING = @"loading";

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

- (void)setStatusWithString:(NSString *)string {
    self.status = string;
}

@end

@implementation UserContextFollow

@end

@implementation UserContextFollowMe

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

@end

@implementation UserContextFollowSubscription

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

@end
