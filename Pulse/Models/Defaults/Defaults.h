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
@class DefaultsKeywordsViewTitles;
@class DefaultsPost;
@class DefaultsPostImgHeight;
@class DefaultsCamp;
@class DefaultsFeed;
@class DefaultsFeedMotd;
@class DefaultsFeedMotdCta;
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
@property (nonatomic) DefaultsCamp <Optional> *camp;
@property (nonatomic) DefaultsFeed <Optional> *feed;

@end

@interface DefaultsKeywords : JSONModel

@property (nonatomic) DefaultsKeywordsViewTitles <Optional> *viewTitles;

@end

@interface DefaultsKeywordsViewTitles : JSONModel

@property (nonatomic) NSString <Optional> *userStream;
@property (nonatomic) NSString <Optional> *discover;
@property (nonatomic) NSString <Optional> *notifications;
@property (nonatomic) NSString <Optional> *myProfile;

@end

@interface DefaultsPost : JSONModel

@property (nonatomic) DefaultsPostImgHeight <Optional> *imgHeight;
@property (nonatomic) NSInteger maxLength;

@end

@interface DefaultsPostImgHeight : JSONModel

@property (nonatomic) NSInteger min;
@property (nonatomic) NSInteger max;

@end

@interface DefaultsCamp : JSONModel

@property (nonatomic) NSInteger scoreThreshold;
@property (nonatomic) NSInteger membersThreshold; // Number of members required to "start" a (default format) public Camp

@end

@interface DefaultsFeed : JSONModel

@property (nonatomic) DefaultsFeedMotd <Optional> *motd;

@end

@interface DefaultsFeedMotd : JSONModel

@property (nonatomic) NSString <Optional> *title;
@property (nonatomic) NSString <Optional> *text;
@property (nonatomic) NSString <Optional> *imageUrl;
@property (nonatomic) DefaultsFeedMotdCta <Optional> *cta;

@end

@interface DefaultsFeedMotdCta : JSONModel

@property (nonatomic) NSString <Optional> *type;
@property (nonatomic) NSString <Optional> *actionUrl;
@property (nonatomic) NSString <Optional> *displayText;

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
