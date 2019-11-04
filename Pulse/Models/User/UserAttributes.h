/**
 * This file is generated using the remodel generation script.
 * The name of the input file is UserAttributes.value
 */

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import "BFContext.h"
#import "UserSummaries.h"
#import "UserMedia.h"

@class UserDetailsLocation;
@class UserDetailsWebsite;

@interface UserAttributes : JSONModel

@property (nonatomic) BFContext <Optional> *context;
@property (nonatomic) UserSummaries <Optional> *summaries;

// details
@property (nonatomic) NSString <Optional> *identifier;
@property (nonatomic) NSString <Optional> *displayName;
@property (nonatomic) NSString <Optional> *bio;
@property (nonatomic) UserDetailsLocation <Optional> *location;
@property (nonatomic) UserDetailsWebsite <Optional> *website;
@property (nonatomic) NSString <Optional> *dob;
@property (nonatomic) NSString <Optional> *color;
@property (nonatomic) UserMedia <Optional> *media;
@property (nonatomic) NSString <Optional> *email;

// status
@property (nonatomic) NSString *createdAt;
@property (nonatomic) BOOL isSuspended;
@property (nonatomic) BOOL isVerified;

@end

@interface UserDetailsLocation : JSONModel

@property (nonatomic) NSString <Optional> *displayText;

@end

@interface UserDetailsWebsite : JSONModel

@property (nonatomic) NSString <Optional> *actionUrl;
@property (nonatomic) NSString <Optional> *displayText;

@end

