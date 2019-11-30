/**
 * This file is generated using the remodel generation script.
 * The name of the input file is User.value
 */

#import <Foundation/Foundation.h>
#import "BFJSONModel.h"
#import "Identity.h"

@protocol User
@end

@class User;
@class UserDetailsLocation;

@interface User : Identity

#pragma mark - API Methods
- (void)subscribeToPostNotifications;
- (void)unsubscribeFromPostNotifications;

- (BOOL)isBirthday;

@end

@interface IdentityAttributes ()

// details
@property (nonatomic) NSString <Optional> *bio;
@property (nonatomic) UserDetailsLocation <Optional> *location;
@property (nonatomic) NSString <Optional> *dob;

@end

@interface IdentitySummariesCounts ()

@property (nonatomic) NSInteger following;

@end

@interface IdentityMedia ()

@property (nonatomic) BFHostedVersions <Optional> *cover;

@end

@interface UserDetailsLocation : BFJSONModel

@property (nonatomic) NSString <Optional> *displayText;

@end
