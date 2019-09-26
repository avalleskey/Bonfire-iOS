//
//  PostImagesView.m
//  Pulse
//
//  Created by Austin Valleskey on 9/20/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "PostImagesView.h"
#import "Session.h"
#import "Launcher.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "Post.h"
#import "UIImage+WithColor.h"
#import "UIColor+Palette.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/UIView+WebCache.h>

#define SPINNER_TAG 11
#define SPINNER_DOT_TAG 12

@implementation PostImagesView

- (id)init {
    self  = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.layer.shouldRasterize = true;
    self.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    self.layer.cornerRadius = 14.f;
    self.layer.masksToBounds = true;
    self.layer.borderWidth = HALF_PIXEL;
    
    self.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.08f].CGColor;
    self.layer.shadowOpacity = 1.f;
    self.layer.shadowOffset = CGSizeMake(0, 1);
    self.layer.shadowRadius = 1.f;
    
    self.imageViews = [[NSMutableArray alloc] init];
    self.media = @[];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // Lay things out again
    [self layoutImageViews];
    
    self.layer.borderColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.1f].CGColor;
}

- (void)setMedia:(NSArray *)media {
    if (media != _media) {
        _media = media;
        
        [self initImageViews];
    }
}

- (void)initImageViews {
    if (_imageViews.count > _media.count) {
        // we need to REMOVE image views
        
        while (_imageViews.count > _media.count) {
            if (_imageViews.count == 0) {
                break;
            }
            
            UIImageView *imageView = [self.imageViews lastObject];
            if (imageView) {
                [imageView removeFromSuperview];
                [self.imageViews removeObject:imageView];
            }
        }
    }
    
    if (self.media.count == 0) {
        // no image views, so stop the code here
        return;
    }
    
    // populate image views with corresponding media
    for (NSInteger i = 0; i < self.media.count; i++) {
        // this should always be true, but we're including the conditional to make sure we never run into an out-of-index bug that crashes the app        
        if ([self.media[i] isKindOfClass:[PostAttachmentsMedia class]] ||
            ([self.media[i] isKindOfClass:[NSString class]] && ((NSString *)self.media[i]).length > 0)) {            
            NSString *imageURL;
            if ([self.media[i] isKindOfClass:[PostAttachmentsMedia class]]) {
                PostAttachmentsMedia *media = (PostAttachmentsMedia *)self.media[i];
                imageURL = media.attributes.hostedVersions.suggested.url;
            }
            else if ([self.media[i] isKindOfClass:[NSString class]] && ((NSString *)self.media[i]).length > 0) {
                imageURL = self.media[i];
            }
            
            if (imageURL) {
                NSURL *url = [NSURL URLWithString:imageURL];
                
                SDAnimatedImageView *animatedImageView = [self animatedImageViewForIndex:i];
                //[self showImageViewSpinner:animatedImageView];
                
                if ([[self MIMETypeFromFileName:imageURL] isEqualToString:@"image/gif"]) {
                    [animatedImageView sd_setImageWithURL:url placeholderImage:nil options:SDWebImageFromLoaderOnly completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                        //[self hideImageViewSpinner:animatedImageView];
                    }];
                    
                }
                else {
                    [animatedImageView sd_setImageWithURL:url placeholderImage:nil options:0 completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                        //[self hideImageViewSpinner:animatedImageView];
                    }];
                }
            }
            else {
                // TODO: Show error image
            }
        }
        else {
            if ([self.media[i] isKindOfClass:[UIImage class]]) {
                SDAnimatedImageView *animatedImageView = [self animatedImageViewForIndex:i];
                [animatedImageView setImage:self.media[i]];
                
                [self hideImageViewSpinner:animatedImageView];
            }
            else if ([self.media[i] isKindOfClass:[NSData class]]) {
                SDAnimatedImageView *animatedImageView = [self animatedImageViewForIndex:i];
                [animatedImageView setImage:[UIImage imageWithData:self.media[i]]];
                
                [self hideImageViewSpinner:animatedImageView];
            }
            else {
                // TODO: Show error image
            }
        }
    }
    
    [self layoutImageViews];
}
- (UIImageView *)imageViewForIndex:(NSInteger)index {
    if (self.imageViews.count > index) {
        if (![[self.imageViews objectAtIndex:index] isKindOfClass:[SDAnimatedImageView class]]) {
            // we already have a UIImageView at that index in which we can return
            return [self.imageViews objectAtIndex:index];
        }
        else {
            // remove existing animated image view and proceed to create a new, ordinary UIImageView
            [self.imageViews removeObjectAtIndex:index];
        }
    }
    
    UIImageView *imageView = [UIImageView new];
    [self setupImageView:imageView];

    [self.imageViews addObject:imageView];
    [self addSubview:imageView];
    [imageView addSubview:[self highlightButtonForImageView:imageView]];
    
    return imageView;
}
- (SDAnimatedImageView *)animatedImageViewForIndex:(NSInteger)index {
    if (self.imageViews.count > index) {
        if ([[self.imageViews objectAtIndex:index] isKindOfClass:[SDAnimatedImageView class]]) {
            // we already have a SDAnimatedImageView at that index in which we can return
            return [self.imageViews objectAtIndex:index];
        }
        else {
            // remove existing image view and proceed to create a new SDAnimatedImageView
            [self.imageViews removeObjectAtIndex:index];
        }
    }
    
    SDAnimatedImageView *imageView = [SDAnimatedImageView new];
    [self setupImageView:imageView];
    
    [self.imageViews addObject:imageView];
    [self addSubview:imageView];
    [imageView addSubview:[self highlightButtonForImageView:imageView]];
    
    return imageView;
}
- (UIButton *)highlightButtonForImageView:(UIImageView *)imageView {
    UIButton *highlightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    highlightButton.tag = 10;
    highlightButton.frame = imageView.bounds;
    [highlightButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.15f animations:^{
            highlightButton.backgroundColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.3];
        }];
    } forControlEvents:UIControlEventTouchDown];
    [highlightButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.15f animations:^{
            highlightButton.backgroundColor = [UIColor clearColor];
        }];
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
    
    [highlightButton bk_whenTapped:^{
        [Launcher exapndImageView:imageView media:self.media imageViews:self.imageViews selectedIndex:imageView.tag];
    }];
    
    return highlightButton;
}
- (void)setupImageView:(UIImageView *)imageView {
    imageView.backgroundColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.05f];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    //imageView.layer.borderWidth = (1 / [UIScreen mainScreen].scale);
    //imageView.layer.borderColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.12f].CGColor;
    imageView.layer.masksToBounds = true;
    imageView.userInteractionEnabled = true;
    imageView.tag = self.imageViews.count;
    imageView.sd_imageTransition = [SDWebImageTransition fadeTransition];
    //[self addSpinnerToImageView:imageView];
}
- (void)addSpinnerToImageView:(UIImageView *)imageView {
    if ([imageView viewWithTag:SPINNER_TAG])
        return;
    
    UIView *spinner = [[UIView alloc] initWithFrame:CGRectMake(imageView.frame.size.width / 2 - 30, imageView.frame.size.height / 2 - 6, 60, 12)];
    spinner.layer.cornerRadius = spinner.frame.size.height / 2;
    spinner.layer.masksToBounds = false;
    spinner.backgroundColor = [UIColor whiteColor];
    //spinner.layer.borderWidth = (1 / [UIScreen mainScreen].scale);
    //spinner.layer.borderColor = [UIColor tableViewSeparatorColor].CGColor;
    spinner.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.08].CGColor;
    spinner.layer.shadowRadius = 1.f;
    spinner.layer.shadowOffset = CGSizeMake(0, 0.5);
    spinner.layer.shadowOpacity = 1.5;
    spinner.tag = SPINNER_TAG;
    
    UIView *spinnerDot = [[UIView alloc] initWithFrame:CGRectMake(3, 3, 16, spinner.frame.size.height - 6)];
    spinnerDot.tag = SPINNER_DOT_TAG;
    spinnerDot.backgroundColor = [UIColor tableViewSeparatorColor];
    spinnerDot.layer.cornerRadius = spinnerDot.frame.size.height / 2;
    [spinner addSubview:spinnerDot];
    
    [imageView addSubview:spinner];
}
- (void)showImageViewSpinner:(UIImageView *)imageView {
    UIView *spinner = [imageView viewWithTag:SPINNER_TAG];
    spinner.hidden = false;
    
    if (spinner) {
        [self startSpinnerForImageView:imageView];
    }
}
- (void)startSpinnerForImageView:(UIImageView *)imageView {
    UIView *spinner = [imageView viewWithTag:SPINNER_TAG];
    UIView *spinnerDot = [spinner viewWithTag:SPINNER_DOT_TAG];
            
    [spinner.layer removeAllAnimations];
    [spinnerDot.layer removeAllAnimations];
    
    imageView.backgroundColor = [UIColor yellowColor];
    
    [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionRepeat|UIViewAnimationOptionAutoreverse animations:^{
        imageView.backgroundColor = [UIColor redColor];
        
        spinnerDot.frame = CGRectMake(spinner.frame.size.width - spinnerDot.frame.size.width - 3, spinnerDot.frame.origin.y, spinnerDot.frame.size.width, spinnerDot.frame.size.height);
    } completion:^(BOOL finished) {
        spinnerDot.frame = CGRectMake(3, 3, spinnerDot.frame.size.width, spinnerDot.frame.size.height);
        imageView.backgroundColor = [UIColor greenColor];
    }];
}
- (void)hideImageViewSpinner:(UIImageView *)imageView {
    UIView *spinner = [imageView viewWithTag:SPINNER_TAG];
    spinner.hidden = true;
    
    if (spinner) {
        UIView *spinnerDot = [spinner viewWithTag:SPINNER_DOT_TAG];
        [spinner.layer removeAllAnimations];
        [spinnerDot.layer removeAllAnimations];
    }
}

- (void)layoutImageViews {
    if (self.imageViews.count == 0)
        return;
    
    if (self.imageViews.count == 1) {
        // full width
        UIImageView *onlyImageView = [self.imageViews firstObject];
        onlyImageView.frame = self.bounds;
        [self resizeInnerViewsForImageView:onlyImageView];
    }
    else {
        CGFloat halfWidth = (self.frame.size.width - 2) / 2;
        CGFloat halfHeight = (self.frame.size.height - 2) / 2;
        
        UIImageView *imageView1 = self.imageViews[0];
        imageView1.frame = CGRectMake(0, 0, halfWidth, self.imageViews.count > 3 ? halfHeight : self.frame.size.height);
        [self resizeInnerViewsForImageView:imageView1];
        
        if (self.imageViews.count > 1) {
            UIImageView *imageView2 = self.imageViews[1];
            imageView2.frame = CGRectMake(self.frame.size.width - halfWidth, 0, halfWidth, self.imageViews.count == 2 ? self.frame.size.height : halfHeight);
            [self resizeInnerViewsForImageView:imageView2];
        }
        if (self.imageViews.count > 2) {
            UIImageView *imageView3 = self.imageViews[2];
            imageView3.frame = CGRectMake(self.imageViews.count == 4 ? 0 : self.frame.size.width - halfWidth, self.frame.size.height - halfHeight, halfWidth, halfHeight);
            [self resizeInnerViewsForImageView:imageView3];
        }
        if (self.imageViews.count > 3) {
            UIImageView *imageView4 = self.imageViews[3];
            imageView4.frame = CGRectMake(self.frame.size.width - halfWidth, self.frame.size.height - halfHeight, halfWidth, halfHeight);
            [self resizeInnerViewsForImageView:imageView4];
        }
    }
    
    //[self startSpinners];
}
- (void)resizeInnerViewsForImageView:(UIImageView *)imageView {
    UIButton *highlightButton = [imageView viewWithTag:10];
    highlightButton.frame = imageView.bounds;
    
    UIView *spinner = [imageView viewWithTag:SPINNER_TAG];
    spinner.center = CGPointMake(imageView.frame.size.width / 2, imageView.frame.size.height / 2);
}

+ (CGFloat)streamImageHeight {
    return [Session sharedInstance].defaults.post.imgHeight;
}

- (void)startSpinners {
    for (UIImageView *imageView in self.imageViews) {
        UIView *spinner = [imageView viewWithTag:SPINNER_TAG];
        if (![spinner isHidden]) {
            [self startSpinnerForImageView:imageView];
        }
    }
}

- (NSString *)MIMETypeFromFileName:(NSString *)fileName {
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[fileName pathExtension], NULL);
    CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType);
    CFRelease(UTI);
    if (!MIMEType) {
        return @"application/octet-stream";
    }
    return (__bridge NSString *)(MIMEType);
}
- (NSString *)mimeTypeForData:(NSData *)data {
    uint8_t c;
    [data getBytes:&c length:1];
    
    switch (c) {
        case 0xFF:
            return @"image/jpeg";
            break;
        case 0x89:
            return @"image/png";
            break;
        case 0x47:
            return @"image/gif";
            break;
        case 0x49:
        case 0x4D:
            return @"image/tiff";
            break;
        case 0x25:
            return @"application/pdf";
            break;
        case 0xD0:
            return @"application/vnd";
            break;
        case 0x46:
            return @"text/plain";
            break;
        default:
            return @"application/octet-stream";
    }
    return nil;
}

@end
