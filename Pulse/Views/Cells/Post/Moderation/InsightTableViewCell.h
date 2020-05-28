//
//  InsightTableViewCell.h
//  Pulse
//
//  Created by Austin Valleskey on 5/27/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface InsightTableViewCell : UITableViewCell

@property (nonatomic, strong) UIView *lineSeparator;

+ (CGFloat)height;

@end

NS_ASSUME_NONNULL_END
