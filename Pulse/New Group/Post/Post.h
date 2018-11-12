/**
 * This file is generated using the remodel generation script.
 * The name of the input file is PostAttributes.value
 */

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import "PostAttributes.h"

@interface Post : JSONModel

@property (nonatomic) NSInteger identifier;
@property (nonatomic) NSString *type;
@property (nonatomic) PostAttributes *attributes;

- (BOOL)requiresURLPreview;

@end

