//
//  HallwayHelpers.m
//  Hallway App
//
//  Created by Austin Valleskey on 8/18/18.
//  Copyright © 2018 Hallway App. All rights reserved.
//

#import "NSArray+Clean.h"
#import "NSDictionary+Clean.h"

@implementation NSArray (Clean)

- (NSArray *)clean {
    NSArray *array = self;
    
    NSMutableArray *replaced = [array mutableCopy];
    const id nul = [NSNull null];
    const NSString *blank = @"";
    for (int idx = 0; idx < [replaced count]; idx++) {
        id object = [replaced objectAtIndex:idx];
        if (object == nul) [replaced replaceObjectAtIndex:idx withObject:blank];
        else if ([object isKindOfClass:[NSDictionary class]]) [replaced replaceObjectAtIndex:idx withObject:[object clean]];
        else if ([object isKindOfClass:[NSArray class]]) [replaced replaceObjectAtIndex:idx withObject:[object clean]];
    }
    return [replaced copy];
}

@end
