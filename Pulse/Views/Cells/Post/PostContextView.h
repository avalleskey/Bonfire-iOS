//
//  PostContextView.h
//  Pulse
//
//  Created by Austin Valleskey on 1/8/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

#define postContextHeight 18

NS_ASSUME_NONNULL_BEGIN

@interface PostContextView : UIView

@property (nonatomic, strong) UILabel *contextLabel;
@property (nonatomic, strong) UIImageView *contextIcon;

@property (nonatomic) NSString *text;
@property (nonatomic) UIImage *icon;

@end

NS_ASSUME_NONNULL_END
