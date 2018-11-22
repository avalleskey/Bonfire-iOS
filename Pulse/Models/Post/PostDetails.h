/**
 * This file is generated using the remodel generation script.
 * The name of the input file is PostDetails.value
 */

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import "User.h"

@interface PostDetails : JSONModel

@property (nonatomic) NSString *message;
@property (nonatomic) BOOL hasMedia;
@property (nonatomic) User *creator;

- (NSString *)simpleMessage;

@end

