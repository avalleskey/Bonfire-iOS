//
//  RoomContext.m
//  Pulse
//
//  Created by Austin Valleskey on 10/21/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "RoomContext.h"

@implementation RoomContext

NSString * const STATUS_INVITED = @"invited";
NSString * const STATUS_REQUESTED = @"requested";
NSString * const STATUS_MEMBER = @"member";
NSString * const STATUS_LEFT = @"left";
NSString * const STATUS_BLOCKED = @"blocked";
NSString * const STATUS_NO_RELATION = @"none";

NSString * const STATUS_ROOM_BLOCKED = @"room_blocked";

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

- (void)setStatusWithString:(NSString *)string {
    NSLog(@"self::::::::: %@", self);
    NSLog(@"self.status:::PPP: %@", self.status);
    
    self.status = string;
}

@end

@implementation RoomContextInvite

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

@end

@implementation RoomContextMembership

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

@end
