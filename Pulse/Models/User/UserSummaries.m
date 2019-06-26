//
//  UserSummaries.m
//  Pulse
//
//  Created by Austin Valleskey on 12/11/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "UserSummaries.h"

@implementation UserSummaries

@end

@implementation UserSummariesCounts

+ (BOOL)propertyIsOptional:(NSString*)propertyName
{
    NSArray *optionalProperties = @[@"posts", @"camps", @"following"];
    if ([optionalProperties containsObject:propertyName]) return YES;
    return NO;
}

@end
