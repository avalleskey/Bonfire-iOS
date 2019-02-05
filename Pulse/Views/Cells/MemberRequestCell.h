//
//  MemberRequestCell.h
//  Pulse
//
//  Created by Austin Valleskey on 10/1/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BFAvatarView.h"

@interface MemberRequestCell : UITableViewCell

@property (strong, nonatomic) BFAvatarView *profilePicture;
@property (strong, nonatomic) UIButton *approveButton;
@property (strong, nonatomic) UIButton *declineButton;

@end