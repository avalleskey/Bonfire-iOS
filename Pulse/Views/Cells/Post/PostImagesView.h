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

@property (strong, nonatomic) NSMutableArray *imageViews;

// array of URLs and/or UIImages
@property (strong, nonatomic) NSArray *media;

+ (CGFloat)streamImageHeight;

@end

NS_ASSUME_NONNULL_END
