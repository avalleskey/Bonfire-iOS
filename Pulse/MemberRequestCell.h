//
//  MemberRequestCell.h
//  Pulse
//
//  Created by Austin Valleskey on 10/1/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MemberRequestCell : UITableViewCell

// ---- VIEWS ----
@property (strong, nonatomic) UIView *selectionBackground;
@property (strong, nonatomic) UIView *lineSeparator;

@property (strong, nonatomic) UIButton *approveButton;
@property (strong, nonatomic) UIButton *declineButton;

@end
