//
//  PaginationCell.h
//  Hallway App
//
//  Created by Austin Valleskey on 6/18/18.
//  Copyright © 2018 Hallway App. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BFActivityIndicatorView.h"

@interface PaginationCell : UITableViewCell

@property (nonatomic, strong) UIView *topSeparator;
@property (nonatomic, strong) UIView *bottomSeparator;

@property BOOL loading;
@property (nonatomic, strong) BFActivityIndicatorView *spinner;

@property (nonatomic, strong) UILabel *label;

+ (CGFloat)height;

@end
