//
//  InsightsLoggerTimeframe.m
//  Pulse
//
//  Created by Austin Valleskey on 1/1/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "InsightsLoggerTimeframe.h"

@implementation InsightsLoggerTimeframe

// SeenIn: on post open
NSString * const InsightSeenInRoomView =  @"room";
NSString * const InsightSeenInPostView = @"post";
NSString * const InsightSeenInProfileView = @"creator_profile";
NSString * const InsightSeenInHomeView = @"/streams/me";
NSString * const InsightSeenInTrendingView = @"/streams/trending";

// Action: on post close
NSString * const InsightActionTypeMediaOpen =  @"media_open";
NSString * const InsightActionTypeProfileOpen = @"profile_open";
NSString * const InsightActionTypeDetailExpand = @"detail_expand";
NSString * const InsightActionTypeLinkOpen = @"link_open";

@synthesize ts_start;
@synthesize ts_end;
@synthesize seen_in;
@synthesize action;
@synthesize actions;

- (id)init {
    self = [super init];
    if (self) {
        ts_start = [NSDate new];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.ts_start = [decoder decodeObjectForKey:@"ts_start"];
        self.ts_end = [decoder decodeObjectForKey:@"ts_end"];
        self.seen_in = [decoder decodeObjectForKey:@"seen_in"];
        self.action = [decoder decodeObjectForKey:@"action"];
        self.actions = [decoder decodeObjectForKey:@"actions"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:ts_start forKey:@"ts_start"];
    [encoder encodeObject:ts_end forKey:@"ts_end"];
    [encoder encodeObject:seen_in forKey:@"seen_in"];
    [encoder encodeObject:action forKey:@"action"];
    [encoder encodeObject:actions forKey:@"actions"];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<InsightsLoggerTimeFrame>\n\n[ts_start]: %@\n\n[ts_end]: %@\n\n[seen_in]: %@\n\n[action]: %@\n\n[actions]: %@", ts_start, ts_end, seen_in, action, actions];
}

@end
