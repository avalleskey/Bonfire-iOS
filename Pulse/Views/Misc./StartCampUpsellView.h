//
//  StartCampUpsellView.h
//  Pulse
//
//  Created by Austin Valleskey on 10/3/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BFAvatarView.h"

NS_ASSUME_NONNULL_BEGIN

@interface StartCampUpsellView : UIView

@property (nonatomic, strong) Camp *camp;

@property (nonatomic, strong) UIView *campAvatarContainer;
@property (nonatomic, strong) BFAvatarView *campAvatarView;
@property (nonatomic, strong) UIImageView *campAvatarPlusIcon;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descriptionLabel;
@property (nonatomic, strong) UIView *actionsView;

@end

NS_ASSUME_NONNULL_END
