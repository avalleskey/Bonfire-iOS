//
//  RoomContext.m
//  Pulse
//
//  Created by Austin Valleskey on 10/21/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "RoomContext.h"

@implementation RoomContext

NSString * const ROOM_STATUS_INVITED = @"invited";
NSString * const ROOM_STATUS_REQUESTED = @"requested";
NSString * const ROOM_STATUS_MEMBER = @"member";
NSString * const ROOM_STATUS_LEFT = @"left";
NSString * const ROOM_STATUS_BLOCKED = @"blocked";
NSString * const ROOM_STATUS_NO_RELATION = @"none";

NSString * const ROOM_STATUS_ROOM_BLOCKED = @"room_blocked";
NSString * const ROOM_STATUS_LOADING = @"loading";

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
