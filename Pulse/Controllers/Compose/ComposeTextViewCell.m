//
//  ComposeTextViewCell.m
//  Pulse
//
//  Created by Austin Valleskey on 3/19/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "ComposeTextViewCell.h"
#import "Session.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/SDAnimatedImageView+WebCache.h>
#import "UIColor+Palette.h"
#import "UITextView+Placeholder.h"
#import "Launcher.h"

@implementation ComposeTextViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.contentView.backgroundColor = [UIColor whiteColor];
        self.tintColor = [UIColor bonfireBrand];
        
        self.textView = [[UITextView alloc] initWithFrame:CGRectMake(70, 12, self.frame.size.width - 70 - 12, self.frame.size.height)];
        self.textView.clipsToBounds = false;
        self.textView.scrollEnabled = false;
        self.textView.backgroundColor = [UIColor clearColor];
        self.textView.font = [UIFont systemFontOfSize:20.f weight:UIFontWeightRegular];
        self.textView.textColor = [UIColor bonfireBlack];
        self.textView.textContainer.lineFragmentPadding = 0;
        self.textView.contentInset = UIEdgeInsetsZero;
        self.textView.textContainerInset = UIEdgeInsetsMake(12, 0, 12, 0);
        self.textView.placeholder = @"Share with everyone...";
        self.textView.keyboardType = UIKeyboardTypeTwitter;
        self.textView.keyboardAppearance = UIKeyboardAppearanceLight;
        self.textView.placeholderColor = [UIColor colorWithRed:0.24 green:0.24 blue:0.26 alpha:0.3];
        [self.contentView addSubview:self.textView];
        
        self.creatorAvatar = [[BFAvatarView alloc] initWithFrame:CGRectMake(12, 12, 48, 48)];
        self.creatorAvatar.user = [Session sharedInstance].currentUser;
        [self.contentView addSubview:self.creatorAvatar];
        
        [self setupImagesView];
        [self setupURLPreviewView];
        
        self.lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height, self.frame.size.width, (1 / [UIScreen mainScreen].scale))];
        self.lineSeparator.backgroundColor = [UIColor separatorColor];
        [self.contentView addSubview:self.lineSeparator];
    }
    
    return self;
}

- (void)setupImagesView {
    self.mediaScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, self.textView.frame.origin.y, self.frame.size.width, 180)];
    self.mediaScrollView.hidden = true;
    self.mediaScrollView.contentInset = UIEdgeInsetsMake(0, self.textView.frame.origin.x, 0, 12);
    self.mediaScrollView.showsHorizontalScrollIndicator = false;
    self.mediaScrollView.showsVerticalScrollIndicator = false;
    [self.contentView addSubview:self.mediaScrollView];
    
    // Stack View
    self.media = [[BFMedia alloc] init];
    self.media.delegate = self;
    self.mediaContainerView = [[UIStackView alloc] initWithFrame:CGRectMake(0, 0, self.mediaScrollView.frame.size.width, self.mediaScrollView.frame.size.height)];
    self.mediaContainerView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2f];
    self.mediaContainerView.axis = UILayoutConstraintAxisHorizontal;
    self.mediaContainerView.distribution = UIStackViewDistributionFill;
    self.mediaContainerView.alignment = UIStackViewAlignmentFill;
    self.mediaContainerView.spacing = 6;
    
    self.mediaContainerView.translatesAutoresizingMaskIntoConstraints = false;
    [self.mediaScrollView addSubview:self.mediaContainerView];
    
    [self.mediaContainerView.leadingAnchor constraintEqualToAnchor:_mediaScrollView.leadingAnchor].active = true;
    [self.mediaContainerView.trailingAnchor constraintEqualToAnchor:_mediaScrollView.trailingAnchor].active = true;
    [self.mediaContainerView.bottomAnchor constraintEqualToAnchor:_mediaScrollView.bottomAnchor].active = true;
    [self.mediaContainerView.topAnchor constraintEqualToAnchor:_mediaScrollView.topAnchor].active = true;
    [self.mediaContainerView.heightAnchor constraintEqualToAnchor:_mediaScrollView.heightAnchor].active = true;
}

- (void)setupURLPreviewView {
    self.urlPreviewView = [[PostURLPreviewView alloc] initWithFrame:CGRectMake(self.textView.frame.origin.x, self.textView.frame.origin.y, self.textView.frame.size.width, URL_PREVIEW_DETAILS_HEIGHT)];
    self.urlPreviewView.delegate = self;
    self.urlPreviewView.editable = true;
    self.urlPreviewView.hidden = true;
    
    [self.urlPreviewView bk_whenTapped:^{
        if (self.urlPreviewView.editable) {
            // confirm action
            UIAlertController *confirmActionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            
            UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"Remove Link" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                self.url = [NSURL URLWithString:@""];
            }];
            [confirmActionSheet addAction:confirmAction];
            
            UIAlertAction *cancelActionSheet = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
            [confirmActionSheet addAction:cancelActionSheet];
            
            [[Launcher activeViewController] presentViewController:confirmActionSheet animated:YES completion:nil];
        }
        else {
            [Launcher openURL:self.url.absoluteString];
        }
    }];
    [self.contentView addSubview:self.urlPreviewView];
}
- (void)URLPreviewWillChangeFrameTo:(CGRect)newFrame {
    [self.delegate mediaDidChange];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self resize];
    
    if (!self.lineSeparator.isHidden) {
        self.lineSeparator.frame = CGRectMake(0, self.frame.size.height - self.lineSeparator.frame.size.height, self.frame.size.width, self.lineSeparator.frame.size.height);
    }
}

- (void)resize {
    [self resizeTextView];
    [self resizeAttachments];
}

- (void)resizeTextView {
    NSString *text = self.textView.text.length > 0 ? self.textView.text : self.textView.placeholder;
    CGSize textViewSize = [text boundingRectWithSize:CGSizeMake(self.frame.size.width - 70 - 12, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.textView.font} context:nil].size;
    NSInteger numLines = textViewSize.height / self.textView.font.lineHeight;
    if (numLines > 1) {
        self.textView.textContainerInset = UIEdgeInsetsMake(8, 0, 12, 0);
    }
    else {
        self.textView.textContainerInset = UIEdgeInsetsMake(12, 0, 12, 0);
    }
    
    CGRect textViewFrame = self.textView.frame;
    textViewFrame.size.width = self.frame.size.width - 70 - 12;
    textViewFrame.size.height = textViewSize.height + self.textView.textContainerInset.top + self.textView.textContainerInset.bottom;
    self.textView.frame = textViewFrame;
}

- (void)resizeAttachments {
    if (self.media.objects.count > 0)
        [self resizeImagesView];
    
    [self resizeURLPreviewView];
}
- (void)resizeImagesView {
    // resize image scroll view
    self.mediaScrollView.frame = CGRectMake(0, self.textView.frame.origin.y + self.textView.frame.size.height + 8, self.frame.size.width, 180);
}

- (void)resizeURLPreviewView {
    self.urlPreviewView.frame = CGRectMake(self.textView.frame.origin.x, self.textView.frame.origin.y + self.textView.frame.size.height + 8, self.textView.frame.size.width, self.urlPreviewView.frame.size.height);
}

- (void)setUrl:(NSURL *)url {
    // NSLog(@"set url: %@", url);
    if (url != _url) {
        _url = url;
        
        self.urlPreviewView.url = url;
        
        if (_url.absoluteString.length == 0) {
            self.urlPreviewView.hidden = true;
        }
        else {
            self.urlPreviewView.hidden = false;
        }
        
        [self.delegate mediaDidChange];
    }
}

- (void)mediaObjectAdded:(BFMediaObject *)object {
    NSLog(@"media object added:: %@", object);
    if (self.mediaScrollView.isHidden) {
        self.mediaScrollView.hidden = false;
    }
    
    NSData *data = object.data;
    
    SDAnimatedImageView *view = [[SDAnimatedImageView alloc] init];
    view.userInteractionEnabled = true;
    view.backgroundColor = [UIColor bonfireGray];
    view.layer.cornerRadius = 12.f;
    view.layer.masksToBounds = true;
    view.contentMode = UIViewContentModeScaleAspectFill;
    if ([object.MIME isEqualToString:BFMediaObjectMIME_GIF]) {
        SDAnimatedImage *animatedImage = [SDAnimatedImage imageWithData:data];
        view.image = animatedImage;
        
        UIImage *image = [UIImage imageWithData:data];
        [view.widthAnchor constraintEqualToAnchor:view.heightAnchor multiplier:(image.size.width/image.size.height)].active = true;
    }
    else {
        view.image = [UIImage imageWithData:data];
        [view.widthAnchor constraintEqualToAnchor:view.heightAnchor multiplier:(view.image.size.width/view.image.size.height)].active = true;
    }
    [view.heightAnchor constraintEqualToConstant:100].active = true;
    view.layer.borderWidth = 1.f;
    view.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.04f].CGColor;
    [view bk_whenTapped:^{
        [Launcher expandImageView:view];
    }];
    [_mediaContainerView addArrangedSubview:view];
    
    UIButton *removeImageButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [removeImageButton setImage:[UIImage imageNamed:@"composeRemoveImageIcon"] forState:UIControlStateNormal];
    removeImageButton.layer.cornerRadius = 15.f;
    removeImageButton.layer.shadowOffset = CGSizeMake(0, 0.5);
    removeImageButton.layer.shadowRadius = 1.f;
    removeImageButton.layer.shadowColor = [UIColor blackColor].CGColor;
    removeImageButton.layer.shadowOpacity = 0.1f;
    removeImageButton.adjustsImageWhenHighlighted = false;
    [view addSubview:removeImageButton];
    // 1
    removeImageButton.translatesAutoresizingMaskIntoConstraints = false;
    [removeImageButton.topAnchor constraintEqualToAnchor:view.topAnchor constant:5].active = true;
    [removeImageButton.rightAnchor constraintEqualToAnchor:view.rightAnchor constant:-5].active = true;
    [removeImageButton.widthAnchor constraintEqualToConstant:30].active = true;
    [removeImageButton.heightAnchor constraintEqualToConstant:30].active = true;
    
    [removeImageButton bk_whenTapped:^{
        [self removeImageAtIndex:[self.mediaContainerView.subviews indexOfObject:view]];
    }];
    [removeImageButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            removeImageButton.alpha = 0.8;
            removeImageButton.transform = CGAffineTransformMakeScale(0.6, 0.6);
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    [removeImageButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            removeImageButton.alpha = 1;
            removeImageButton.transform = CGAffineTransformMakeScale(1, 1);
        } completion:nil];
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
    
    [self.delegate mediaDidChange];
}

- (void)removeImageAtIndex:(NSInteger)index {
    if (self.mediaContainerView.subviews.count > index) {
        UIView *view = [self.mediaContainerView.subviews objectAtIndex:index];
        view.userInteractionEnabled = false;
        
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            view.transform = CGAffineTransformMakeScale(0.6, 0.6);
            view.alpha = 0.01;
        } completion:nil];
        [UIView animateWithDuration:0.4f delay:0.15 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            view.hidden = true;
        } completion:^(BOOL finished) {
            [view removeFromSuperview];
            if (self.media.objects.count == 0) {
                self.mediaScrollView.hidden = true;
            }
        }];
    }
    
    if (self.media.objects.count > index) {
        BFMediaObject *object = [self.media.objects objectAtIndex:index];
        
        [self.media removeObject:object];
    }

    [self.delegate mediaDidChange];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (CGFloat)height {
    float minHeight = 48 + 12 + 12;
    
    float height = self.textView.textContainerInset.top; // top padding
    float textViewHeight = self.textView.frame.size.height;
    height = height + textViewHeight;
    
    if (self.media.objects.count > 0) {
        float imagesHeight = 8 + 180;
        height = height + imagesHeight;
    }
    
    if (self.url.absoluteString.length > 0) {
        float urlPreviewHeight = 8 + [self.urlPreviewView height];
        height = height + urlPreviewHeight;
    }
    
    // add bottom padding
    height = height + 12;
    
    return (height > minHeight ? height : minHeight);
}

@end
