/**
 * This file is generated using the remodel generation script.
 * The name of the input file is PostStatus.value
 */

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import "Room.h"
#import "PostStatusDisplay.h"

@interface PostStatus : JSONModel

@property (nonatomic) Room <Optional> *postedIn;
@property (nonatomic) NSString *createdAt;
@property (nonatomic) PostStatusDisplay *display;

@end

