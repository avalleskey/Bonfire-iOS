//
//  LinkPostCell.h
//  Hallway App
//
//  Created by Austin Valleskey on 5/30/18.
//  Copyright © 2018 Hallway App. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIImageView+WebCache.h"
#import <UIFont+Poppins.h>

#import <BlocksKit/BlocksKit+UIKit.h>
#import <ResponsiveLabel/ResponsiveLabel.h>
#import "BFAvatarView.h"
#import "PostActivityView.h"
#import "ExpandedPostActionsView.h"
#import "TappableView.h"

#define expandedImageHeightDefault 240

#define expandedLinkContentOffset UIEdgeInsetsMake(0, 12, 0, 12)
#define expandedLinkTitleLabelFont [UIFont systemFontOfSize:24.f weight:UIFontWeightBold]
#define expandedLinkTextViewFont [UIFont systemFontOfSize:14.f weight:UIFontWeightRegular]
#define expandedLinkActionsViewHeight 44

@interface LinkPostCell : UITableViewCell

@property BOOL loading;

@property (nonatomic, strong) BFLink *link;

// Views
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *summaryLabel;
@property (nonatomic, strong) UIImageView *imagePreviewView;

@property (nonatomic, strong) UIButton *postedInButton;
@property (nonatomic, strong) UILabel *linkURLLabel;

@property (nonatomic, strong) PostActivityView *activityView;

@property (nonatomic, strong) UIView *activityLineSeparator;
@property (nonatomic, strong) UIView *lineSeparator;

+ (CGFloat)heightForLink:(BFLink *)link width:(CGFloat)contentWidth;

@end
