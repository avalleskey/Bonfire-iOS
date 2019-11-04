//
//  BFHostedVersions.m
//  Pulse
//
//  Created by Austin Valleskey on 5/3/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFHostedVersions.h"

@implementation BFHostedVersions

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError **)err {
    BFHostedVersions *instance = [super initWithDictionary:dict error:err];
    instance.suggested = instance.full;
    
    return instance;
}

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return true;
}

@end

@implementation BFHostedVersionObject

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return true;
}

@end
