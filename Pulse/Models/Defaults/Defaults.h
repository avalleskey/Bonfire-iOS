//
//  Defaults.h
//  Pulse
//
//  Created by Austin Valleskey on 10/17/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "BFJSONModel.h"

@class Defaults;
@class DefaultsKeywords;
@class DefaultsKeywordsViewTitles;
@class DefaultsPost;
@class DefaultsPostImgHeight;
@class DefaultsCamp;
@class DefaultsAnnouncement;
@class DefaultsAnnouncementAttributes;
@class DefaultsAnnouncementAttributesCta;
@class DefaultsLogging;
@class DefaultsLoggingInsights;
@class DefaultsLoggingInsightsImpressions;
@class DefaultsLoggingInsightsImpressionsBatching;
@class DefaultsNotificationsFormat;

NS_ASSUME_NONNULL_BEGIN

@interface Defaults : BFJSONModel
 
@property (nonatomic) DefaultsKeywords <Optional> *keywords;
@property (nonatomic) DefaultsLogging <Optional> *logging;
@property (nonatomic) NSDictionary <Optional> *notifications;
@property (nonatomic) DefaultsPost <Optional> *post;
@property (nonatomic) DefaultsCamp <Optional> *camp;
@property (nonatomic) DefaultsAnnouncement <Optional> * _Nullable announcement;

@end

@interface DefaultsKeywords : BFJSONModel

@property (nonatomic) DefaultsKeywordsViewTitles <Optional> *viewTitles;

@end

@interface DefaultsKeywordsViewTitles : BFJSONModel

@property (nonatomic) NSString <Optional> *userStream;
@property (nonatomic) NSString <Optional> *discover;
@property (nonatomic) NSString <Optional> *notifications;
@property (nonatomic) NSString <Optional> *myProfile;

@end

@interface DefaultsPost : BFJSONModel

@property (nonatomic) DefaultsPostImgHeight <Optional> *imgHeight;
@property (nonatomic) NSInteger maxLength;

@end

@interface DefaultsPostImgHeight : BFJSONModel

@property (nonatomic) NSInteger min;
@property (nonatomic) NSInteger max;

@end

@interface DefaultsCamp : BFJSONModel

@property (nonatomic) NSInteger scoreThreshold;
@property (nonatomic) NSInteger membersThreshold; // Number of members required to "start" a (default format) public Camp

@end

@interface DefaultsAnnouncement : BFJSONModel

@property (nonatomic) NSString <Optional> *identifier;
@property (nonatomic) NSString <Optional> *type; // == "announcement"
@property (nonatomic) DefaultsAnnouncementAttributes <Optional> *attributes;

#pragma mark - API Handlers
- (void)dismissWithCompletion:(void (^_Nullable)(BOOL success, id __nullable responseObject))completion;
- (void)ctaTappedWithCompletion:(void (^_Nullable)(BOOL success, id __nullable responseObject))completion;

@end

@interface DefaultsAnnouncementAttributes : BFJSONModel

@property (nonatomic) NSString <Optional> *title;
@property (nonatomic) NSString <Optional> *text;
@property (nonatomic) NSString <Optional> *imageUrl;
@property (nonatomic) DefaultsAnnouncementAttributesCta <Optional> *cta;

@end

@interface DefaultsAnnouncementAttributesCta : BFJSONModel

@property (nonatomic) NSString <Optional> *type;
@property (nonatomic) NSString <Optional> *actionUrl;
@property (nonatomic) NSString <Optional> *displayText;

@end

@interface DefaultsLogging : BFJSONModel

@property (nonatomic) DefaultsLoggingInsights <Optional> *insights;

@end

@interface DefaultsLoggingInsights : BFJSONModel

@property (nonatomic) DefaultsLoggingInsightsImpressions <Optional> *impressions;

@end

@interface DefaultsLoggingInsightsImpressions : BFJSONModel

@property (nonatomic) DefaultsLoggingInsightsImpressionsBatching <Optional> *batching;

@end

@interface DefaultsLoggingInsightsImpressionsBatching : BFJSONModel

@property (nonatomic) NSInteger maxTimeframes;
@property (nonatomic) NSInteger maxLengthHrs;

@end

// Used inside each notification
// e.g.
// defaults
// -> notifications
// -> -> 3
// -> -> -> DefaultsNotificationsFormat
@interface DefaultsNotificationsFormat : BFJSONModel

extern NSString * const ACTIVITY_ACTION_OBJECT_ACTIONER;
extern NSString * const ACTIVITY_ACTION_OBJECT_POST;
extern NSString * const ACTIVITY_ACTION_OBJECT_REPLY_POST;
extern NSString * const ACTIVITY_ACTION_OBJECT_CAMP;

@property (nonatomic) NSArray <Optional> *stringParts;
@property (nonatomic) NSString <Optional> *actionObject;

@end

NS_ASSUME_NONNULL_END
