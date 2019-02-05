//
//  Defaults.h
//  Pulse
//
//  Created by Austin Valleskey on 10/17/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "JSONModel.h"

@class Defaults;
@class DefaultsHome;
@class DefaultsProfile;
@class DefaultsPost;
@class DefaultsPostDisplayVote;
@class DefaultsSharing;
@class DefaultsRoom;
@class DefaultsRoomMembersTitle;
@class DefaultsOnboarding;
@class DefaultsOnboardingMyRooms;
@class DefaultsLogging;
@class DefaultsLoggingInsights;
@class DefaultsLoggingInsightsImpressions;
@class DefaultsLoggingInsightsImpressionsBatching;

NS_ASSUME_NONNULL_BEGIN

@interface Defaults : JSONModel

@property (nonatomic) DefaultsHome <Optional> *home;
@property (nonatomic) DefaultsProfile <Optional> *profile;
@property (nonatomic) DefaultsPost <Optional> *post;
@property (nonatomic) DefaultsSharing <Optional> *sharing;
@property (nonatomic) DefaultsRoom <Optional> *room;
@property (nonatomic) DefaultsOnboarding <Optional> *onboarding;
@property (nonatomic) DefaultsLogging <Optional> *logging;

@end

@interface DefaultsHome : JSONModel

@property (nonatomic) NSString <Optional> *feedPageTitle;
@property (nonatomic) NSString <Optional> *myRoomsPageTitle;
@property (nonatomic) NSString <Optional> *discoverPageTitle;

@end

@interface DefaultsProfile : JSONModel

@property (nonatomic) NSString <Optional> *followVerb;
@property (nonatomic) NSString <Optional> *followingVerb;

@end

@interface DefaultsPost : JSONModel

@property (nonatomic) DefaultsPostDisplayVote <Optional> *displayVote;
@property (nonatomic) NSInteger imgHeight;
@property (nonatomic) NSInteger maxLength;
@property (nonatomic) NSString <Optional> *composePrompt;

@end

@interface DefaultsPostDisplayVote : JSONModel

@property (nonatomic) NSString <Optional> *text;
@property (nonatomic) NSString <Optional> *icon;

@end

@interface DefaultsSharing : JSONModel

@property (nonatomic) NSString <Optional> *sharePost;
@property (nonatomic) NSString <Optional> *shareRoom;

@end

@interface DefaultsRoom : JSONModel

@property (nonatomic) NSString <Optional> *createVerb;
@property (nonatomic) NSString <Optional> *followVerb;
@property (nonatomic) NSString <Optional> *followingVerb;
@property (nonatomic) DefaultsRoomMembersTitle <Optional> *membersTitle;
@property (nonatomic) NSInteger liveThreshold;
@property (nonatomic) NSInteger activeThreshold;

@end

@interface DefaultsRoomMembersTitle : JSONModel

@property (nonatomic) NSString <Optional> *singular;
@property (nonatomic) NSString <Optional> *plural;

@end

@interface DefaultsOnboarding : JSONModel

@property (nonatomic) DefaultsOnboardingMyRooms <Optional> *myRooms;

@end

@interface DefaultsOnboardingMyRooms : JSONModel

@property (nonatomic) NSString <Optional> *title;
@property (nonatomic) NSString <Optional> *theDescription;

@end

@interface DefaultsLogging : JSONModel

@property (nonatomic) DefaultsLoggingInsights <Optional> *insights;

@end

@interface DefaultsLoggingInsights : JSONModel

@property (nonatomic) DefaultsLoggingInsightsImpressions <Optional> *impressions;

@end

@interface DefaultsLoggingInsightsImpressions : JSONModel

@property (nonatomic) DefaultsLoggingInsightsImpressionsBatching <Optional> *batching;

@end

@interface DefaultsLoggingInsightsImpressionsBatching : JSONModel

@property (nonatomic) NSInteger max_timeframes;
@property (nonatomic) NSInteger max_length_hrs;

@end

NS_ASSUME_NONNULL_END
