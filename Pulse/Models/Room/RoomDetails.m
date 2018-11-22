#import "RoomDetails.h"

@implementation RoomDetails

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                                                                  @"theDescription": @"description"
                                                                  }];
}

@end

