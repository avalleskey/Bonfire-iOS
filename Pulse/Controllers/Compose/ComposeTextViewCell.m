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

@interface ComposeTextViewCell ()

@end

@implementation ComposeTextViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.backgroundColor = [UIColor contentBackgroundColor];
        self.contentView.backgroundColor = [UIColor contentBackgroundColor];
        self.tintColor = [UIColor bonfireBrand];
        
        self.textView = [[UITextView alloc] initWithFrame:CGRectMake(64, 12, self.frame.size.width - 64 - 12, self.frame.size.height)];
        self.textView.clipsToBounds = false;
        self.textView.scrollEnabled = false;
        self.textView.backgroundColor = [UIColor clearColor];
        self.textView.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightRegular];
        self.textView.textColor = [UIColor bonfirePrimaryColor];
        self.textView.textContainer.lineFragmentPadding = 0;
        self.textView.contentInset = UIEdgeInsetsZero;
        self.textView.textContainerInset = UIEdgeInsetsMake(9, 0, 9, 0);
        self.textView.placeholder = @"Share with everyone...";
        self.textView.keyboardType = UIKeyboardTypeTwitter;
        self.textView.editable = true;
        self.textView.selectable = true;
        self.textView.placeholderColor = [[UIColor bonfirePrimaryColor] colorWithAlphaComponent:0.3];
        [self.contentView addSubview:self.textView];
        
        self.creatorAvatar = [[BFAvatarView alloc] initWithFrame:CGRectMake(12, 12, 42, 42)];
        self.creatorAvatar.user = [Session sharedInstance].currentUser;
        [self.contentView addSubview:self.creatorAvatar];
        
        [self setupImagesView];
        
        self.topLine = [[UIView alloc] initWithFrame:CGRectMake(self.creatorAvatar.frame.origin.x + self.creatorAvatar.frame.size.width / 2 - (3 / 2), 0, 3, 0)];
        self.topLine.backgroundColor = [UIColor threadLineColor];
        self.topLine.layer.cornerRadius = self.topLine.frame.size.width / 2;
        self.topLine.hidden = true;
        [self.contentView addSubview:self.topLine];
        
        self.lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height, self.frame.size.width, (1 / [UIScreen mainScreen].scale))];
        self.lineSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
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
    //self.mediaContainerView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2f];
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

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self resize];
    
    if (![self.topLine isHidden]) {
        self.topLine.frame = CGRectMake(self.creatorAvatar.frame.origin.x + (self.creatorAvatar.frame.size.width / 2) - (self.topLine.frame.size.width / 2), -2, 3, (self.creatorAvatar.frame.origin.y - 4) + 2);
    }
    
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
    CGSize textViewSize = [text boundingRectWithSize:CGSizeMake(self.frame.size.width - 64 - 12, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.textView.font} context:nil].size;
    NSInteger numLines = textViewSize.height / self.textView.font.lineHeight;
    if (numLines > 1) {
        self.textView.textContainerInset = UIEdgeInsetsMake(5, 0, 9, 0);
    }
    else {
        self.textView.textContainerInset = UIEdgeInsetsMake(9, 0, 9, 0);
    }
    
    CGRect textViewFrame = self.textView.frame;
    textViewFrame.size.width = self.frame.size.width - 64 - 12;
    textViewFrame.size.height = ceilf(textViewSize.height) + self.textView.textContainerInset.top + self.textView.textContainerInset.bottom;
    self.textView.frame = textViewFrame;
}

- (void)resizeAttachments {
    if (self.media.objects.count > 0) {
        [self resizeImagesView];
    }
    
    if (self.quotedAttachmentView) {
        [self resizeQuotedAttachment];
    }
}

- (void)resizeImagesView {
    // resize image scroll view
    self.mediaScrollView.frame = CGRectMake(0, self.textView.frame.origin.y + self.textView.frame.size.height + 12, self.frame.size.width, 180);
}

- (void)resizeQuotedAttachment {
    if (!self.quotedAttachmentView) {
        return;
    }
    
    if (self.media.objects.count == 0) {
        self.quotedAttachmentView.frame = CGRectMake(self.textView.frame.origin.x, self.textView.frame.origin.y + self.textView.frame.size.height + 12, self.textView.frame.size.width, self.quotedAttachmentView.frame.size.height);
    }
    else {
        self.quotedAttachmentView.frame = CGRectMake(self.textView.frame.origin.x, self.mediaScrollView.frame.origin.y + self.mediaScrollView.frame.size.height + 12, self.textView.frame.size.width, self.quotedAttachmentView.frame.size.height);
    }
    SetHeight(self.quotedAttachmentView, [self.quotedAttachmentView height]);
    [self.quotedAttachmentView layoutSubviews];
}
- (void)setQuotedAttachmentView:(BFAttachmentView *)quotedAttachmentView {
    if (quotedAttachmentView != _quotedAttachmentView) {
        if (_quotedAttachmentView) {
            // remove existing, changed attachment view from the view hierarchy
            [_quotedAttachmentView removeFromSuperview];
        }
        
        _quotedAttachmentView = quotedAttachmentView;
        _quotedAttachmentView.userInteractionEnabled = false;
        
        [self.contentView addSubview:quotedAttachmentView];
        
        [self layoutSubviews];
        [self.delegate mediaDidChange];
    }
}

- (void)mediaObjectAdded:(BFMediaObject *)object {
    if (self.mediaScrollView.isHidden) {
        self.mediaScrollView.hidden = false;
    }
    
    NSData *data = object.data;
    
    SDAnimatedImageView *view = [[SDAnimatedImageView alloc] init];
    view.userInteractionEnabled = true;
    view.backgroundColor = [UIColor bonfireSecondaryColor];
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
    view.layer.borderColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.06].CGColor;
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
    float minHeight = 42 + 12 + 12;
    
    float height = self.textView.textContainerInset.top; // top padding
    float textViewHeight = self.textView.frame.size.height;
    height += textViewHeight;
    
    if (self.media.objects.count > 0) {
        float imagesHeight = 12 + 180;
        height += imagesHeight;
    }
    
    // add height of attachments
    if (self.quotedAttachmentView) {
        float attachmentViewHeight = 12 + self.quotedAttachmentView.frame.size.height;
        height += attachmentViewHeight;
    }
    
    // add bottom padding
    height += 12;
    
    return MAX(minHeight, height);
}

@end
