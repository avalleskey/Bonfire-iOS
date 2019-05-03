/**
 * This file is generated using the remodel generation script.
 * The name of the input file is User.value
 */

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import "UserAttributes.h"

@interface User : JSONModel

@property (nonatomic) NSString <Optional> *identifier;
@property (nonatomic) NSString <Optional> *type;
@property (nonatomic) UserAttributes <Optional> *attributes;

// helper methods
- (BOOL)isVerified;

@end

