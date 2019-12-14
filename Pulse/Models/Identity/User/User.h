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
@class UserAttributesInvites;
@class UserDetailsLocation;

@interface User : Identity

#pragma mark - API Methods
- (void)subscribeToPostNotifications;
- (void)unsubscribeFromPostNotifications;

- (BOOL)isBirthday;

@end

@interface IdentityAttributes ()

@property (nonatomic) BOOL requiresInvite;
@property (nonatomic) NSString <Optional> *bio;
@property (nonatomic) UserDetailsLocation <Optional> *location;
@property (nonatomic) NSString <Optional> *dob;
@property (nonatomic) UserAttributesInvites <Optional> *invites;

@end

@interface UserAttributesInvites : BFJSONModel

@property (nonatomic) NSInteger numAvailable;
@property (nonatomic) NSString <Optional> *friendCode;

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
