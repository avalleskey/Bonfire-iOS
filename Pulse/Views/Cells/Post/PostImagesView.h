//
//  PostImagesView.h
//  Pulse
//
//  Created by Austin Valleskey on 9/20/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SDAnimatedImageView+WebCache.h>
#import "Post.h"

NS_ASSUME_NONNULL_BEGIN

@interface PostImagesView : UIView <SDWebImageManagerDelegate>

@property (nonatomic, strong) NSMutableArray *imageViews;

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UITextView *captionTextView;

// array of URLs and/or UIImages
@property (nonatomic, strong) NSArray *media;
@property (nonatomic, strong) NSString *caption;

+ (BOOL)useCaptionedImageViewForPost:(Post *)post;
+ (CGFloat)streamImageHeight;

- (void)startSpinnersAsNeeded;

@end

NS_ASSUME_NONNULL_END
