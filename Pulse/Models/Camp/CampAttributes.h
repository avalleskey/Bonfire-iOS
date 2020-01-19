/**
 * This file is generated using the remodel generation script.
 * The name of the input file is CampAttributes.value
 */

#import <Foundation/Foundation.h>
#import "BFJSONModel.h"
#import "CampSummaries.h"
#import "BFContext.h"
#import "CampMedia.h"
#import "BFLink.h"

NS_ASSUME_NONNULL_BEGIN

@class CampDisplay;

@interface CampAttributes : BFJSONModel

@property (nonatomic) CampSummaries <Optional> *summaries;
@property (nonatomic) BFContext <Optional> *context;
@property (nonatomic) CampDisplay <Optional> *display;

// details
@property (nonatomic) NSString <Optional> *identifier;
@property (nonatomic) NSString <Optional> *title;
@property (nonatomic) NSString <Optional> *theDescription;
@property (nonatomic) NSString <Optional> *color;
@property (nonatomic) CampMedia <Optional> *media;

// status
@property (nonatomic) BOOL isSuspended; // derived from "suspended"
@property (nonatomic) NSString <Optional> *createdAt;
@property (nonatomic) BOOL isVerified; // derived from "verified"

// visibility
@property (nonatomic) BOOL isPrivate; // derived from "private"

@end

@interface CampDisplay : BFJSONModel

extern NSString * const CAMP_DISPLAY_FORMAT_CHANNEL;
extern NSString *const CAMP_DISPLAY_FORMAT_FEED;
@property (nonatomic) NSString <Optional> *format;

@property (nonatomic) NSObject <Optional> * _Nullable source;

#pragma mark - Generated properties
// if the source is a user, sourceUser will exist
@property (nonatomic) User <Optional> * _Nullable sourceUser;

// if the source is a link, sourceLink will exist
@property (nonatomic) BFLink <Optional> * _Nullable sourceLink;

@end

NS_ASSUME_NONNULL_END
