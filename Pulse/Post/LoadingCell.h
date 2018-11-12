//
//  PostCell.h
//  Pulse
//
//  Created by Austin Valleskey on 5/30/18.
//  Copyright © 2018 Hallway App. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIImageView+WebCache.h"
#import <BlocksKit/BlocksKit+UIKit.h>
#import "Post.h"
#import "PostTextView.h"
#import "PostImagesView.h"
#import "PostSurveyView.h"
#import "PostActionsView.h"
#import <Shimmer/FBShimmeringView.h>

#define loadingPostContentOffset UIEdgeInsetsMake(12, 62, 12, 12)

#define loadingCellTypeShortPost 0
#define loadingCellTypeLongPost 1
#define loadingCellTypePicturePost 2

@interface LoadingCell : UITableViewCell <UITextFieldDelegate>

// @property (strong) NSDictionary *theme;
@property (nonatomic) NSInteger type;
@property (nonatomic) BOOL hasPicture;

// Views
@property (strong, nonatomic) UIView *shimmerContentView;
@property (strong, nonatomic) FBShimmeringView *shimmerContainer;
@property (strong, nonatomic) UIView *textView;
@property (strong, nonatomic) UIView *profilePicture;
@property (strong, nonatomic) UIView *pictureView;
@property (strong, nonatomic) UIView *nameLabel;

@property (strong, nonatomic) UIView *lineSeparator;

@end
