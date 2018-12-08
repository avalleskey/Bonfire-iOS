//
//  PostCell.h
//  Pulse
//
//  Created by Austin Valleskey on 5/30/18.
//  Copyright © 2018 Hallway App. All rights reserved.
//

#import "BubblePostCell.h"
#import <Shimmer/FBShimmeringView.h>

#define loadingCellTypeShortPost 0
#define loadingCellTypeLongPost 1
#define loadingCellTypePicturePost 2

@interface LoadingCell : BubblePostCell

// @property (strong) NSDictionary *theme;
@property (nonatomic) NSInteger type;
@property (nonatomic) BOOL hasPicture;

// Views
@property (strong, nonatomic) UIView *shimmerContentView;
@property (strong, nonatomic) FBShimmeringView *shimmerContainer;

@end
