//
//  PostModerationInsightsTableViewCell.h
//  Pulse
//
//  Created by Austin Valleskey on 9/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Post.h"

@interface PostModerationInsightsTableViewCell : UITableViewCell <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *lineSeparator;

@property (nonatomic, strong) Post *post;
@property (nonatomic, strong) NSArray *insights;

+ (CGFloat)heightForPost:(Post *)post;

@end
