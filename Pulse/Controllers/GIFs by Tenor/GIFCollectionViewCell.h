//
//  GIFCollectionViewCell.h
//  Pulse
//
//  Created by Austin Valleskey on 3/4/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SDAnimatedImageView+WebCache.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/UIView+WebCache.h>

NS_ASSUME_NONNULL_BEGIN

@interface GIFCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) SDAnimatedImageView *gifPlayerView;

@property (nonatomic) BOOL touchDown;
@property (nonatomic) BOOL loading;
@property (nonatomic) BOOL fetchingFullGif;

@property (nonatomic, strong) NSString *gifUrl;
@property (nonatomic, strong) NSString *fullGifUrl;

@end

NS_ASSUME_NONNULL_END
