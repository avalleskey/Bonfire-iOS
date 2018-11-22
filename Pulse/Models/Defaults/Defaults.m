//
//  Defaults.m
//  Pulse
//
//  Created by Austin Valleskey on 10/17/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "Defaults.h"

@implementation Defaults

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

@end

@implementation DefaultsHome

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                                                                  @"feedPageTitle": @"page_titles.feed",
                                                                  @"myRoomsPageTitle": @"page_titles.my_rooms",
                                                                  @"discoverPageTitle": @"page_titles.discover"
                                                                  }];
}

@end

@implementation DefaultsProfile

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

@end

@implementation DefaultsPost

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

@end

@implementation DefaultsPostDisplayVote

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

@end

@implementation DefaultsSharing

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

@end

@implementation DefaultsRoom

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

@end

@implementation DefaultsRoomMembersTitle

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

@end

@implementation DefaultsOnboarding

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

@end

@implementation DefaultsOnboardingMyRooms

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                                                                  @"theDescription": @"description"
                                                                  }];
}

@end
