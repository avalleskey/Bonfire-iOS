//
//  BFJSONModel.m
//  Pulse
//
//  Created by Austin Valleskey on 11/14/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFJSONModel.h"

@implementation BFJSONModel

-(id)initWithDictionary:(NSDictionary*)dict error:(NSError**)err
{
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    return [super initWithDictionary:dict error:err];
}

@end
