//
//  HallwayHelpers.m
//  Hallway App
//
//  Created by Austin Valleskey on 8/18/18.
//  Copyright © 2018 Hallway App. All rights reserved.
//

#import "NSDictionary+Clean.h"
#import "NSArray+Clean.h"

@implementation NSDictionary (Clean)

- (NSDictionary *)clean {
    NSDictionary *dictionary = self;
    
    const NSMutableDictionary *replaced = [dictionary mutableCopy];
    const id nul = [NSNull null];
    const NSString *blank = @"";
    
    for (NSString *key in dictionary) {
        id object = [dictionary objectForKey:key];
        if (object == nul) [replaced setObject:blank forKey:key];
        else if ([object isKindOfClass:[NSDictionary class]]) [replaced setObject:[object clean] forKey:key];
        else if ([object isKindOfClass:[NSArray class]]) [replaced setObject:[object clean] forKey:key];
    }
    return [NSDictionary dictionaryWithDictionary:[replaced copy]];
}

@end
