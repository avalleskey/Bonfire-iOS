//
//  RoomMedia.h
//  Pulse
//
//  Created by Austin Valleskey on 5/3/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "JSONModel.h"
#import "BFHostedVersions.h"

NS_ASSUME_NONNULL_BEGIN

@interface RoomMedia : JSONModel

@property (nonatomic) BFHostedVersions <Optional> *roomAvatar;

@end

NS_ASSUME_NONNULL_END
