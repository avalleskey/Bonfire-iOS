//
//  BFHostedVersions.h
//  Pulse
//
//  Created by Austin Valleskey on 5/3/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "JSONModel.h"

NS_ASSUME_NONNULL_BEGIN

@class BFHostedVersionObject;

@interface BFHostedVersions : JSONModel

@property (nonatomic) BFHostedVersionObject <Optional> *suggested;

@property (nonatomic) BFHostedVersionObject <Optional> *full;
@property (nonatomic) BFHostedVersionObject <Optional> *lg;
@property (nonatomic) BFHostedVersionObject <Optional> *md;
@property (nonatomic) BFHostedVersionObject <Optional> *sm;
@property (nonatomic) BFHostedVersionObject <Optional> *xs;

@end

@interface BFHostedVersionObject : JSONModel

@property (nonatomic) NSString *url;

@end

NS_ASSUME_NONNULL_END