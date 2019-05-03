//
//  BFHostedVersions.m
//  Pulse
//
//  Created by Austin Valleskey on 5/3/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFHostedVersions.h"

@implementation BFHostedVersions

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

- (BFHostedVersionObject *)suggested {
    return self.full;
}

@end

@implementation BFHostedVersionObject

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

@end
