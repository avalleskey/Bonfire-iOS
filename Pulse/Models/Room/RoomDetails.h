/**
 * This file is generated using the remodel generation script.
 * The name of the input file is RoomDetails.value
 */

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import "RoomMedia.h"

@interface RoomDetails : JSONModel

@property (nonatomic) NSString <Optional> *identifier;
@property (nonatomic) NSString <Optional> *title;
@property (nonatomic) NSString <Optional> *theDescription;
@property (nonatomic) NSString <Optional> *color;
@property (nonatomic) RoomMedia <Optional> *media;

@end

