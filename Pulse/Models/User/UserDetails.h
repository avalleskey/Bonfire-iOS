/**
 * This file is generated using the remodel generation script.
 * The name of the input file is UserDetails.value
 */

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import "UserMedia.h"

@interface UserDetails : JSONModel

@property (nonatomic) NSString *identifier;
@property (nonatomic) NSString *displayName;
@property (nonatomic) NSString *color;
@property (nonatomic) UserMedia <Optional> *media;

@end

