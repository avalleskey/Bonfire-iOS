//
//  OutOfDateClientViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 8/12/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OutOfDateClientViewController : UIViewController

@property (nonatomic, strong) UILabel *topInfoPill;
@property (nonatomic, strong) UIButton *nextButton;

@property (nonatomic, strong) UIView *infoView;

@end

NS_ASSUME_NONNULL_END
