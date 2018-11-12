//
//  InputCell.h
//  Pulse
//
//  Created by Austin Valleskey on 10/24/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface InputCell : UITableViewCell

@property (strong, nonatomic) UILabel *inputLabel;
@property (strong, nonatomic) UITextField *input;

@end

NS_ASSUME_NONNULL_END
