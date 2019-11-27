#import "User.h"

@implementation User

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                                                                  @"identifier": @"id"
                                                                  }];
}

- (BOOL)validate:(NSError **)error
{
    if (![super validate:error])
        return NO;

    if ([self.type isEqualToString:@"user"])
    {
        return NO;
    }

    return YES;
}

#pragma mark - Helper methods
- (BOOL)isVerified {
    return [self.attributes isVerified];
}

@end
