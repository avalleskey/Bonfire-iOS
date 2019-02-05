/**
 * This file is generated using the remodel generation script.
 * The name of the input file is UserDetails.value
 */

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import "UserMedia.h"

@class UserDetailsLocation;
@class UserDetailsWebsite;

@interface UserDetails : JSONModel

@property (nonatomic) NSString <Optional> *identifier;
@property (nonatomic) NSString <Optional> *displayName;
@property (nonatomic) NSString <Optional> *bio;
@property (nonatomic) UserDetailsLocation <Optional> *location;
@property (nonatomic) UserDetailsWebsite <Optional> *website;
@property (nonatomic) NSString <Optional> *dob;
@property (nonatomic) NSString <Optional> *color;
@property (nonatomic) UserMedia <Optional> *media;

@end

@interface UserDetailsLocation : JSONModel

@property (nonatomic) NSString <Optional> *value;

@end

@interface UserDetailsWebsite : JSONModel

@property (nonatomic) NSString <Optional> *value;

@end
