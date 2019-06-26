//
//  Defaults.h
//  Pulse
//
//  Created by Austin Valleskey on 10/17/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "JSONModel.h"

@class Defaults;
@class DefaultsKeywords;
@class DefaultsKeywordsGroupTitles;
@class DefaultsKeywordsViewTitles;
@class DefaultsProfile;
@class DefaultsPost;
@class DefaultsPostMaxLength;
@class DefaultsSharing;
@class DefaultsCamp;
@class DefaultsCampMembersTitle;
@class DefaultsLogging;
@class DefaultsLoggingInsights;
@class DefaultsLoggingInsightsImpressions;
@class DefaultsLoggingInsightsImpressionsBatching;
@class DefaultsNotificationsFormat;

NS_ASSUME_NONNULL_BEGIN

@interface Defaults : JSONModel

@property (nonatomic) DefaultsKeywords <Optional> *keywords;
@property (nonatomic) DefaultsLogging <Optional> *logging;
@property (nonatomic) NSDictionary <Optional> *notifications;
@property (nonatomic) DefaultsPost <Optional> *post;
@property (nonatomic) DefaultsProfile <Optional> *profile;
@property (nonatomic) DefaultsCamp <Optional> *camp;
@property (nonatomic) DefaultsSharing <Optional> *sharing;

@end

@interface DefaultsKeywords : JSONModel

@property (nonatomic) DefaultsKeywordsGroupTitles <Optional> *groupTitles;
@property (nonatomic) DefaultsKeywordsViewTitles <Optional> *viewTitles;

@end

@interface DefaultsKeywordsGroupTitles : JSONModel

@property (nonatomic) NSString <Optional> *singular;
@property (nonatomic) NSString <Optional> *plural;

@end

@interface DefaultsKeywordsViewTitles : JSONModel

@property (nonatomic) NSString <Optional> *userStream;
@property (nonatomic) NSString <Optional> *discover;
@property (nonatomic) NSString <Optional> *notifications;
@property (nonatomic) NSString <Optional> *myProfile;

@end

@interface DefaultsProfile : JSONModel

@property (nonatomic) NSString <Optional> *followVerb;
@property (nonatomic) NSString <Optional> *followingVerb;

@end

@interface DefaultsPost : JSONModel

@property (nonatomic) NSInteger imgHeight;
@property (nonatomic) DefaultsPostMaxLength <Optional> *maxLength;
@property (nonatomic) NSString <Optional> *composePrompt;

@end

@interface DefaultsPostMaxLength : JSONModel

@property (nonatomic) NSInteger hard;
@property (nonatomic) NSInteger soft;

@end

@interface DefaultsSharing : JSONModel

@property (nonatomic) NSString <Optional> *sharePost;
@property (nonatomic) NSString <Optional> *shareCamp;

@end

@interface DefaultsCamp : JSONModel

@property (nonatomic) NSString <Optional> *followVerb;
@property (nonatomic) NSString <Optional> *followingVerb;
@property (nonatomic) DefaultsCampMembersTitle <Optional> *membersTitle;
@property (nonatomic) NSInteger liveThreshold;

@end

@interface DefaultsCampMembersTitle : JSONModel

@property (nonatomic) NSString <Optional> *singular;
@property (nonatomic) NSString <Optional> *plural;

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

@property (nonatomic) NSInteger maxTimeframes;
@property (nonatomic) NSInteger maxLengthHrs;

@end

// Used inside each notification
// e.g.
// defaults
// -> notifications
// -> -> 3
// -> -> -> DefaultsNotificationsFormat
@interface DefaultsNotificationsFormat : JSONModel

extern NSString * const ACTIVITY_ACTION_OBJECT_ACTIONER;
extern NSString * const ACTIVITY_ACTION_OBJECT_POST;
extern NSString * const ACTIVITY_ACTION_OBJECT_REPLY_POST;
extern NSString * const ACTIVITY_ACTION_OBJECT_CAMP;

@property (nonatomic) NSArray <Optional> *stringParts;
@property (nonatomic) NSString <Optional> *actionObject;

@end

NS_ASSUME_NONNULL_END
