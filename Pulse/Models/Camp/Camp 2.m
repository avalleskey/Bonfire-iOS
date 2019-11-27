#import "Camp.h"

@implementation Camp

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return TRUE;
}
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

    if ([self.type isEqualToString:@"camp"])
    {
        return NO;
    }

    return YES;
}

#pragma mark - Helper methods
- (BOOL)isVerified {
    return self.attributes.isVerified;
}

@end

@implementation NSArray (CampArray)

- (NSArray <Camp *> *)toCampArray {
    NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithArray:self];
    [mutableArray enumerateObjectsUsingBlock:^(NSDictionary *object, NSUInteger idx, BOOL *stop) {
        if ([object isKindOfClass:[NSDictionary class]]) {
            [mutableArray replaceObjectAtIndex:idx withObject:[[Camp alloc] initWithDictionary:object error:nil]];
        }
    }];
    
    return [mutableArray copy];
}
- (NSArray <NSDictionary *> *)toCampDictionaryArray {
    NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithArray:self];
    [mutableArray enumerateObjectsUsingBlock:^(Camp *object, NSUInteger idx, BOOL *stop) {
        if ([object isKindOfClass:[Camp class]]) {
            [mutableArray replaceObjectAtIndex:idx withObject:[object toDictionary]];
        }
    }];
    
    return [mutableArray copy];
}

@end
