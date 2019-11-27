#import "Bot.h"

@implementation Bot

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                                                                  @"identifier": @"id"
                                                                  }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return true;
}

- (BOOL)validate:(NSError **)error
{
    if (![super validate:error])
        return NO;

    if ([self.type isEqualToString:@"bot"])
    {
        return NO;
    }

    return YES;
}

#pragma mark - Helper methods
- (BOOL)isVerified {
    return self.attributes.verified;
}

@end
