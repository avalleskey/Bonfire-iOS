//
//  PostImagesView.h
//  Pulse
//
//  Created by Austin Valleskey on 9/20/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SDAnimatedImageView+WebCache.h>

NS_ASSUME_NONNULL_BEGIN

@interface PostImagesView : UIView <SDWebImageManagerDelegate>

@property (nonatomic, strong) NSMutableArray *imageViews;

@property (nonatomic, strong) UIView *containerView;

// array of URLs and/or UIImages
@property (nonatomic, strong) NSArray *media;

+ (CGFloat)streamImageHeight;

@end

NS_ASSUME_NONNULL_END
