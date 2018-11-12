#import "RoomStatus.h"

@implementation RoomStatus

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

@end

