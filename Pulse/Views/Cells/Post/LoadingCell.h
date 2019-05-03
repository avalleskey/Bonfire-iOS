//
//  LoadingCell.h
//  Pulse
//
//  Created by Austin Valleskey on 5/30/18.
//  Copyright © 2018 Hallway App. All rights reserved.
//

#import "PostCell.h"
#import <Shimmer/FBShimmeringView.h>

#define loadingCellTypeShortPost 0
#define loadingCellTypeLongPost 1
#define loadingCellTypePicturePost 2

@interface LoadingCell : PostCell

// @property (strong) NSDictionary *theme;
@property (nonatomic) NSInteger type;
@property (nonatomic) BOOL hasPicture;

// Views
@property (nonatomic, strong) UIView *shimmerContentView;
@property (nonatomic, strong) FBShimmeringView *shimmerContainer;

@end
