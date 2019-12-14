//
//  Identity.h
//  Pulse
//
//  Created by Austin Valleskey on 11/5/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFJSONModel.h"
#import "BFHostedVersions.h"
#import "BFContext.h"

NS_ASSUME_NONNULL_BEGIN

@protocol Identity
@end

@class Identity;
@class IdentityAttributes;
@class IdentityAttributesWebsite;
@class IdentityMedia;
@class IdentitySummaries;
@class IdentitySummariesCounts;

@interface Identity : BFJSONModel

@property (nonatomic) NSString <Optional> *identifier;
@property (nonatomic) NSString <Optional> *type; // = "bot" || "user"
@property (nonatomic) IdentityAttributes <Optional> *attributes;

// helper methods
- (BOOL)isVerified;
- (BOOL)isBot;
- (BOOL)isCurrentIdentity;

@end

@interface IdentityAttributes : BFJSONModel

@property (nonatomic) NSString <Optional> *identifier;
@property (nonatomic) NSString <Optional> *displayName;
@property (nonatomic) IdentityAttributesWebsite <Optional> *website;
@property (nonatomic) NSString <Optional> *color;
@property (nonatomic) IdentityMedia <Optional> *media;
@property (nonatomic) NSString <Optional> *email;

@property (nonatomic) BFContext <Optional> *context;
@property (nonatomic) IdentitySummaries <Optional> *summaries;

// status
@property (nonatomic) NSString *createdAt;
@property (nonatomic) BOOL isSuspended;
@property (nonatomic) BOOL isVerified;

@end

@interface IdentityAttributesWebsite : BFJSONModel

@property (nonatomic) NSString <Optional> *actionUrl;
@property (nonatomic) NSString <Optional> *displayUrl;

@end

@interface IdentityMedia : BFJSONModel

@property (nonatomic) BFHostedVersions <Optional> *avatar;

@end

@interface IdentitySummaries : BFJSONModel

@property (nonatomic) IdentitySummariesCounts <Optional> *counts;

@end

@interface IdentitySummariesCounts : BFJSONModel

@property (nonatomic) NSInteger posts;
@property (nonatomic) NSInteger camps;

@end

NS_ASSUME_NONNULL_END
