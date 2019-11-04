//
//  SpacerCell.h
//  Pulse
//
//  Created by Austin Valleskey on 10/9/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SpacerCell : UITableViewCell

@property (nonatomic, strong) UIView *topSeparator;
@property (nonatomic, strong) UIView *bottomSeparator;

+ (CGFloat)height;

@end

NS_ASSUME_NONNULL_END
