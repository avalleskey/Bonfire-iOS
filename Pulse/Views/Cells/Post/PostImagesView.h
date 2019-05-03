//
//  PostImagesView.h
//  Pulse
//
//  Created by Austin Valleskey on 9/20/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIImageView+WebCache.h"

NS_ASSUME_NONNULL_BEGIN

@interface PostImagesView : UIView

@property (nonatomic, strong) NSMutableArray *imageViews;

// array of URLs and/or UIImages
@property (nonatomic, strong) NSArray *media;

+ (CGFloat)streamImageHeight;

@end

NS_ASSUME_NONNULL_END
