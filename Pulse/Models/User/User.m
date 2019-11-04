#import "User.h"

@implementation User

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                                                                  @"identifier": @"id"
                                                                  }];
}

#pragma mark - Helper methods
- (BOOL)isVerified {
    return [self.attributes isVerified];
}

@end
