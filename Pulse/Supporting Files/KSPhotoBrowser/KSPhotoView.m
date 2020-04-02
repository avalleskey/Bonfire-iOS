//
//  KSPhotoView.m
//  KSPhotoBrowser
//
//  Created by Kyle Sun on 12/25/16.
//  Copyright © 2016 Kyle Sun. All rights reserved.
//

#import "KSPhotoView.h"
#import "KSPhotoItem.h"
#import "KSProgressView.h"
#import "KSPhotoBrowser.h"

const CGFloat kKSPhotoViewPadding = 10;
const CGFloat kKSPhotoViewMaxScale = 3;

static UIColor *BackgroundColor = nil;

@interface KSPhotoView ()<UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong, readwrite) UIImageView *imageView;
@property (nonatomic, strong, readwrite) KSProgressView *progressView;
@property (nonatomic, strong, readwrite) KSPhotoItem *item;

@end

@implementation KSPhotoView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.bouncesZoom = YES;
        self.maximumZoomScale = kKSPhotoViewMaxScale;
        self.multipleTouchEnabled = YES;
        self.showsHorizontalScrollIndicator = YES;
        self.showsVerticalScrollIndicator = YES;
        self.delegate = self;
        if (@available(iOS 11.0, *)) {
            self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        
        _imageView = [[[KSPhotoBrowser.imageManagerClass imageViewClass]  alloc] init];
        _imageView.backgroundColor = KSPhotoView.backgroundColor;
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        [self addSubview:_imageView];
        [self resizeImageView];
        
        _progressView = [[KSProgressView alloc] initWithFrame:CGRectMake(0, 0, 52, 52)];
        [self addSubview:_progressView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _progressView.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
}

- (void)setItem:(KSPhotoItem *)item determinate:(BOOL)determinate {
    _item = item;
    [KSPhotoBrowser.imageManagerClass cancelImageRequestForImageView:_imageView];
    
    if (item) {
        if (item.image) {
            _imageView.image = item.image;
            _item.finished = YES;
            [_progressView stopSpin];
            [self resizeImageView];
            return;
        }
        __weak typeof(self) wself = self;
//        KSImageManagerProgressBlock progressBlock = nil;
//        if (determinate) {
//            progressBlock = ^(NSInteger receivedSize, NSInteger expectedSize) {
//                __strong typeof(wself) sself = wself;
//                double progress = (double)receivedSize / expectedSize;
//                sself.progressView.hidden = NO;
//            };
//        } else {
//            [_progressView startSpin];
//        }
        [_progressView startSpin];
        
        _imageView.image = item.thumbImage;
        [KSPhotoBrowser.imageManagerClass setImageForImageView:_imageView withURL:item.imageUrl placeholder:item.thumbImage progress:nil completion:^(UIImage *image, NSURL *url, BOOL finished, NSError *error) {
            __strong typeof(wself) sself = wself;
            if (finished) {
                [sself resizeImageView];
            }
            [sself.progressView stopSpin];
            sself.item.finished = YES;
        }];
    } else {
        [_progressView stopSpin];
        _imageView.image = nil;
    }
    [self resizeImageView];
}

- (void)resizeImageView {
    if (_imageView.image) {
        UIEdgeInsets safeAreaInsets = [UIApplication sharedApplication].delegate.window.safeAreaInsets;
        CGFloat maxHeight = self.bounds.size.height - (HAS_ROUNDED_CORNERS && self.tag == 0 ? safeAreaInsets.top + safeAreaInsets.bottom : 0);
        
        CGSize imageSize = _imageView.image.size;
        CGFloat width = self.frame.size.width - 2 * kKSPhotoViewPadding;
        CGFloat height = width * (imageSize.height / imageSize.width);
        if (height > maxHeight) {
            CGFloat ratio = height / maxHeight;
            height = maxHeight;
            width = width / ratio;
        }
        
        CGRect rect = CGRectMake(0, 0, width, height);
        
        _imageView.frame = rect;
        
        // If image is very high, show top content.
        CGFloat yTopBound = (HAS_ROUNDED_CORNERS ? safeAreaInsets.top : 0);
        CGFloat adjustedHeight = self.bounds.size.height - (HAS_ROUNDED_CORNERS ? safeAreaInsets.top + safeAreaInsets.bottom : 0);
        
        if (height <= self.bounds.size.height) {
            _imageView.center = CGPointMake(self.bounds.size.width/2, yTopBound + (adjustedHeight/2));
        } else {
            _imageView.center = CGPointMake(self.bounds.size.width/2, height/2);
        }
        
        // If image is very wide, make sure user can zoom to fullscreen.
        if (width / height > 2) {
            self.maximumZoomScale = self.bounds.size.height / height;
        }
    } else {
        CGFloat width = self.frame.size.width - 2 * kKSPhotoViewPadding;
        _imageView.frame = CGRectMake(0, 0, width, width * 2.0 / 3);
        _imageView.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    }
    self.contentSize = _imageView.frame.size;
    self.zoomScale = 1.f;
}

- (void)cancelCurrentImageLoad {
    [KSPhotoBrowser.imageManagerClass cancelImageRequestForImageView:_imageView];
    [_progressView stopSpin];
}

- (BOOL)isScrollViewOnTopOrBottom {
    CGPoint translation = [self.panGestureRecognizer translationInView:self];
    if (translation.y > 0 && self.contentOffset.y <= 0) {
        return YES;
    }
    CGFloat maxOffsetY = floor(self.contentSize.height - self.bounds.size.height);
    if (translation.y < 0 && self.contentOffset.y >= maxOffsetY) {
        return YES;
    }
    return NO;
}

#pragma mark - ScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    CGFloat offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width)?
    (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
    
    CGFloat offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height)?
    (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
    
    _imageView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX,
                                 scrollView.contentSize.height * 0.5 + offsetY);
}

#pragma mark - GestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == self.panGestureRecognizer) {
        if (gestureRecognizer.state == UIGestureRecognizerStatePossible) {
            if ([self isScrollViewOnTopOrBottom]) {
                return NO;
            }
        }
    }
    return YES;
}

#pragma mark - Setter & Getter

+ (void)setBackgroundColor:(UIColor *)backgroundColor {
    BackgroundColor = backgroundColor;
}

+ (UIColor *)backgroundColor {
    return BackgroundColor ?: [UIColor clearColor];
}


@end
