/**
 * This file is generated using the remodel generation script.
 * The name of the input file is CampDetails.value
 */

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import "CampMedia.h"

@interface CampDetails : JSONModel

@property (nonatomic) NSString <Optional> *identifier;
@property (nonatomic) NSString <Optional> *title;
@property (nonatomic) NSString <Optional> *theDescription;
@property (nonatomic) NSString <Optional> *color;
@property (nonatomic) CampMedia <Optional> *media;

@end

