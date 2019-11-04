//
//  BFErrorViewCell.h
//  Pulse
//
//  Created by Austin Valleskey on 10/9/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BFVisualErrorView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BFErrorViewCell : UITableViewCell

@property (nonatomic, strong) BFVisualErrorView *visualErrorView;

@property (nonatomic, strong) BFVisualError *visualError;

@property (nonatomic, strong) UIView *separator;

+ (CGFloat)heightForVisualError:(BFVisualError *)visualError;

@end

NS_ASSUME_NONNULL_END
