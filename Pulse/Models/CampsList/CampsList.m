//
//  CampsList.m
//  Pulse
//
//  Created by Austin Valleskey on 7/23/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "CampsList.h"

@implementation CampsList

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return TRUE;
}
+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                                                                  @"identifier": @"id"
                                                                  }];
}


@end

@implementation CampsListAttributes

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return TRUE;
}

@end

@implementation NSArray (CampsListArray)

- (NSArray <CampsList *> *)toCampsListArray {
    NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithArray:self];
    [mutableArray enumerateObjectsUsingBlock:^(NSDictionary *object, NSUInteger idx, BOOL *stop) {
        if ([object isKindOfClass:[NSDictionary class]]) {
            [mutableArray replaceObjectAtIndex:idx withObject:[[CampsList alloc] initWithDictionary:object error:nil]];
        }
    }];
    
    return [mutableArray copy];
}
- (NSArray <NSDictionary *> *)toCampsListDictionaryArray {
    NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithArray:self];
    [mutableArray enumerateObjectsUsingBlock:^(CampsList *object, NSUInteger idx, BOOL *stop) {
        if ([object isKindOfClass:[CampsList class]]) {
            [mutableArray replaceObjectAtIndex:idx withObject:[object toDictionary]];
        }
    }];
    
    return [mutableArray copy];
}

@end
