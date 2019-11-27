//
//  Camp.h
//  Pulse
//
//  Created by Austin Valleskey on 5/3/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFJSONModel.h"
#import "BFHostedVersions.h"

NS_ASSUME_NONNULL_BEGIN

@interface CampMedia : BFJSONModel

@property (nonatomic) BFHostedVersions <Optional> *avatar;
@property (nonatomic) BFHostedVersions <Optional> *cover;

@end

NS_ASSUME_NONNULL_END
