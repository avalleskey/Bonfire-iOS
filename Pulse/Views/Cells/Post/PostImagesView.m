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
#import <SDWebImage/UIImageView+WebCache.h>

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
    
    self.layer.cornerRadius = 16.f;
    self.layer.masksToBounds = true;
    self.layer.borderWidth = (1 / [UIScreen mainScreen].scale);
    self.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:1].CGColor;
    
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
                                
                if ([[self MIMETypeFromFileName:imageURL] isEqualToString:@"image/gif"]) {
                    [animatedImageView sd_setImageWithURL:url placeholderImage:nil options:(SDWebImageFromLoaderOnly)];
                }
                else {
                    [animatedImageView sd_setImageWithURL:url];
                }
            }
            else {
                // TODO: Show error image
            }
        }
        else {
            if ([self.media[i] isKindOfClass:[UIImage class]]) {
                if ([self.media[i] isKindOfClass:[SDAnimatedImage class]]) {
                    SDAnimatedImageView *animatedImageView = [self animatedImageViewForIndex:i];
                    [animatedImageView setImage:self.media[i]];
                }
                else {
                    SDAnimatedImageView *animatedImageView = [self animatedImageViewForIndex:i];
                    [animatedImageView setImage:self.media[i]];
                }
            }
            else if ([self.media[i] isKindOfClass:[NSData class]]) {
                NSLog(@"so yeah.... this happened");
                
                SDAnimatedImageView *animatedImageView = [self animatedImageViewForIndex:i];
                [animatedImageView setImage:[UIImage imageWithData:self.media[i]]];
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
        [UIView animateWithDuration:0.2f animations:^{
            highlightButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3f];
        }];
    } forControlEvents:UIControlEventTouchDown];
    [highlightButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.2f animations:^{
            highlightButton.backgroundColor = [UIColor clearColor];
        }];
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
    
    [highlightButton bk_whenTapped:^{
        [Launcher exapndImageView:imageView media:self.media imageViews:self.imageViews selectedIndex:imageView.tag];
    }];
    
    return highlightButton;
}
- (void)setupImageView:(UIImageView *)imageView {
    imageView.backgroundColor = [UIColor colorWithRed:0.93 green:0.93 blue:0.95 alpha:1.0];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.layer.borderWidth = (1 / [UIScreen mainScreen].scale);
    imageView.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.1f].CGColor;
    imageView.layer.masksToBounds = true;
    imageView.userInteractionEnabled = true;
    imageView.tag = self.imageViews.count;
}

- (void)layoutImageViews {
    if (self.imageViews.count == 0)
        return;
    
    if (self.imageViews.count == 1) {
        // full width
        UIImageView *onlyImageView = [self.imageViews firstObject];
        onlyImageView.frame = self.bounds;
        [self resizeHighlightButtonForImageView:onlyImageView];
    }
    else {
        CGFloat halfWidth = (self.frame.size.width - 2) / 2;
        CGFloat halfHeight = (self.frame.size.height - 2) / 2;
        
        UIImageView *imageView1 = self.imageViews[0];
        imageView1.frame = CGRectMake(0, 0, halfWidth, self.imageViews.count > 3 ? halfHeight : self.frame.size.height);
        [self resizeHighlightButtonForImageView:imageView1];
        
        if (self.imageViews.count > 1) {
            UIImageView *imageView2 = self.imageViews[1];
            imageView2.frame = CGRectMake(self.frame.size.width - halfWidth, 0, halfWidth, self.imageViews.count == 2 ? self.frame.size.height : halfHeight);
            [self resizeHighlightButtonForImageView:imageView2];
        }
        if (self.imageViews.count > 2) {
            UIImageView *imageView3 = self.imageViews[2];
            imageView3.frame = CGRectMake(self.imageViews.count == 4 ? 0 : self.frame.size.width - halfWidth, self.frame.size.height - halfHeight, halfWidth, halfHeight);
            [self resizeHighlightButtonForImageView:imageView3];
        }
        if (self.imageViews.count > 3) {
            UIImageView *imageView4 = self.imageViews[3];
            imageView4.frame = CGRectMake(self.frame.size.width - halfWidth, self.frame.size.height - halfHeight, halfWidth, halfHeight);
            [self resizeHighlightButtonForImageView:imageView4];
        }
        
    }
}
- (void)resizeHighlightButtonForImageView:(UIImageView *)imageView {
    UIButton *highlightButton = [imageView viewWithTag:10];
    
    highlightButton.frame = imageView.bounds;
}

+ (CGFloat)streamImageHeight {
    return [Session sharedInstance].defaults.post.imgHeight;
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
