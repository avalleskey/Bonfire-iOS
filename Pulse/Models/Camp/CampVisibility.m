#import "CampVisibility.h"

@implementation CampVisibility

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                                                                  @"isPrivate": @"private"
                                                                  }];
}

+ (BOOL)propertyIsOptional:(NSString*)propertyName
{
    return YES;
}

@end

