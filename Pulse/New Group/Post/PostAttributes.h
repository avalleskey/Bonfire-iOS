//
//  PostAttributes.h
//  Pulse
//
//  Created by Austin Valleskey on 10/9/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <JSONModel/JSONModel.h>
#import "PostDetails.h"
#import "PostStatus.h"
#import "PostSummaries.h"
#import "PostContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface PostAttributes : JSONModel

@property (nonatomic) PostDetails *details;
@property (nonatomic) PostStatus *status;
@property (nonatomic) PostSummaries *summaries;
@property (nonatomic) PostContext *context;

@end

NS_ASSUME_NONNULL_END
