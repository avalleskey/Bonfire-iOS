//
//  GIFCollectionViewCell.m
//  Pulse
//
//  Created by Austin Valleskey on 3/4/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import "GIFCollectionViewCell.h"
#import "UIColor+Palette.h"
#import "BFActivityIndicatorView.h"

@interface GIFCollectionViewCell ()

@property (nonatomic, strong) UIButton *highlightView;
@property (nonatomic, strong) BFActivityIndicatorView *activityIndicator;

@end

@implementation GIFCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        self.gifPlayerView = [[SDAnimatedImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        self.gifPlayerView.layer.masksToBounds = true;
        self.gifPlayerView.sd_imageTransition = [SDWebImageTransition fadeTransition];
        self.gifPlayerView.backgroundColor = [[UIColor bonfireSecondaryColor] colorWithAlphaComponent:0.3f];
        self.gifPlayerView.contentMode = UIViewContentModeScaleAspectFill;
        [self.contentView addSubview:self.gifPlayerView];
        
        self.highlightView = [UIButton buttonWithType:UIButtonTypeCustom];
        self.highlightView.frame = self.contentView.bounds;
        self.highlightView.enabled = false;
        self.highlightView.alpha = 0;
        self.highlightView.layer.cornerRadius = self.layer.cornerRadius;
        self.highlightView.layer.masksToBounds = true;
        [self addSubview:self.highlightView];
        
        self.activityIndicator = [[BFActivityIndicatorView alloc] init];
        self.activityIndicator.hidden = true;
        self.activityIndicator.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        self.activityIndicator.color = [UIColor whiteColor];
        [self addSubview:self.activityIndicator];
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.gifPlayerView.frame = self.contentView.bounds;
    self.gifPlayerView.backgroundColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.1f];
    
    self.highlightView.frame = self.contentView.bounds;
    self.highlightView.backgroundColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.08f];
    
    self.activityIndicator.frame = self.contentView.bounds;
}

- (void)setGifUrl:(NSString *)gifUrl {
    if (![gifUrl isEqualToString:_gifUrl]) {
        _gifUrl = gifUrl;
        
        self.loading = true;
                
        [self.gifPlayerView sd_setImageWithURL:[NSURL URLWithString:gifUrl] placeholderImage:nil options:0 completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            self.loading = false;
        }];
    }
}

- (void)setTouchDown:(BOOL)touchDown {
    if (touchDown != _touchDown) {
        _touchDown = touchDown;
        
        [UIView animateWithDuration:0.2f animations:^{
            self.highlightView.alpha = (touchDown ? 1 : 0);
        }];
    }
}

- (void)setLoading:(BOOL)loading {
    if (loading != _loading) {
        _loading = loading;
        
        if (loading) {
            self.gifPlayerView.image = nil;
            
            CABasicAnimation *opacityAnimation;
            opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
            opacityAnimation.autoreverses = true;
            opacityAnimation.fromValue = [NSNumber numberWithFloat:0.25];
            opacityAnimation.toValue = [NSNumber numberWithFloat:1];
            opacityAnimation.duration = 1.f;
            opacityAnimation.fillMode = kCAFillModeBoth;
            opacityAnimation.repeatCount = HUGE_VALF;
            opacityAnimation.removedOnCompletion = false;
            [self.contentView.layer addAnimation:opacityAnimation forKey:@"opacityAnimation"];
        }
        else {
            [self.contentView.layer removeAllAnimations];
        }
    }
}

- (void)setFetchingFullGif:(BOOL)fetchingFullGif {
    if (fetchingFullGif != _fetchingFullGif) {
        _fetchingFullGif = fetchingFullGif;
        
        if (fetchingFullGif) {
            self.activityIndicator.hidden = false;
            
            [self.activityIndicator startAnimating];
        }
        else {
            [self.activityIndicator stopAnimating];
        }
        
        [UIView animateWithDuration:0.2f animations:^{
            self.activityIndicator.alpha = (fetchingFullGif ? 1 : 0);
        }];
    }
}

@end
