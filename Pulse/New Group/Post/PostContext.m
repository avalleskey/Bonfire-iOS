//
//  PostContext.m
//  Pulse
//
//  Created by Austin Valleskey on 11/7/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "PostContext.h"

@implementation PostContext

@end

@implementation PostContextReplies

@end

@implementation PostContextVote

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

@end
