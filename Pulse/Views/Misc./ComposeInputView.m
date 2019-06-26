//
//  ComposeInputView.m
//  Pulse
//
//  Created by Austin Valleskey on 9/25/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "ComposeInputView.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "Session.h"
#import "UIColor+Palette.h"
#import "Launcher.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/SDAnimatedImageView+WebCache.h>
#import <Photos/Photos.h>

#import "PostViewController.h"
#import "CampViewController.h"
#import "ProfileViewController.h"
#import <HapticHelper/HapticHelper.h>

#define headerHeight 58
#define postButtonShrinkScale 0.9

#define TEXT_VIEW_WITH_IMAGE_X 56
#define TEXT_VIEW_WITHOUT_IMAGE_X 12

#define UIViewParentController(__view) ({ \
    UIResponder *__responder = __view; \
    while ([__responder isKindOfClass:[UIView class]]) \
    __responder = [__responder nextResponder]; \
    (UIViewController *)__responder; \
    })

@implementation ComposeInputView {
    NSString *defaultPlaceholder;
    NSString *mediaPlaceholder;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}
- (id)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    
    return self;
}

- (void)setup {
    self.post = [[Post alloc] init];
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    self.frame = CGRectMake(0, self.frame.origin.y, screenWidth, self.frame.size.height);
    
    self.contentView = [[UIView alloc] initWithFrame:self.bounds];
    self.contentView.backgroundColor = [UIColor contentBackgroundColor];
    [self addSubview:self.contentView];
    
    self.layer.masksToBounds = false;
    
    UIView *hairline = [[UIView alloc] initWithFrame:CGRectMake(0, -(1 / [UIScreen mainScreen].scale), screenWidth, (1 / [UIScreen mainScreen].scale))];
    hairline.backgroundColor = [UIColor separatorColor];
    [self addSubview:hairline];
    
    // text view
    _textView = [[UITextView alloc] initWithFrame:CGRectMake(TEXT_VIEW_WITH_IMAGE_X, 6, self.frame.size.width - TEXT_VIEW_WITH_IMAGE_X - 12, 40)];
    _textView.editable = true;
    _textView.scrollEnabled = false;
    _textView.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightRegular];
    _textView.textContainer.lineFragmentPadding = 0;
    _textView.contentInset = UIEdgeInsetsZero;
    _textView.textContainerInset = UIEdgeInsetsMake(9, 12, 9, 44);
    _textView.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
    _textView.textColor = [UIColor bonfireBlack];
    _textView.layer.cornerRadius = 20.f;
    _textView.backgroundColor = [[UIColor fromHex:@"9FA6AD"] colorWithAlphaComponent:0.1];
    _textView.layer.borderWidth = (1 / [UIScreen mainScreen].scale);
    _textView.layer.borderColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.06f].CGColor;
    _textView.placeholder = defaultPlaceholder;
    _textView.placeholderColor = [UIColor bonfireGray];
    _textView.keyboardAppearance = UIKeyboardAppearanceLight;
    [self.contentView addSubview:_textView];
    
    _mediaScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 8, _textView.frame.size.width, 140 - 16)];
    _mediaScrollView.hidden = true;
    _mediaScrollView.contentInset = UIEdgeInsetsMake(0, 8, 0, 8);
    _mediaScrollView.showsHorizontalScrollIndicator = false;
    _mediaScrollView.showsVerticalScrollIndicator = false;
    [self.textView addSubview:_mediaScrollView];
    
    self.mediaLineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, _mediaScrollView.frame.origin.y +  _mediaScrollView.frame.size.height + 7, _mediaScrollView.frame.size.width, 1)];
    self.mediaLineSeparator.backgroundColor = [UIColor colorWithWhite:0 alpha:0.06f];
    self.mediaLineSeparator.hidden = true;
    [self.textView addSubview:self.mediaLineSeparator];
    
    // Stack View
    self.media = [[BFMedia alloc] init];
    self.media.delegate = self;
    _mediaContainerView = [[UIStackView alloc] initWithFrame:CGRectMake(0, 0, _mediaScrollView.frame.size.width, _mediaScrollView.frame.size.height)];
    _mediaContainerView.backgroundColor = [UIColor whiteColor];
    _mediaContainerView.axis = UILayoutConstraintAxisHorizontal;
    _mediaContainerView.distribution = UIStackViewDistributionFill;
    _mediaContainerView.alignment = UIStackViewAlignmentFill;
    _mediaContainerView.spacing = 6;
    
    _mediaContainerView.translatesAutoresizingMaskIntoConstraints = false;
    [_mediaScrollView addSubview:_mediaContainerView];
    
    [_mediaContainerView.leadingAnchor constraintEqualToAnchor:_mediaScrollView.leadingAnchor].active = true;
    [_mediaContainerView.trailingAnchor constraintEqualToAnchor:_mediaScrollView.trailingAnchor].active = true;
    [_mediaContainerView.bottomAnchor constraintEqualToAnchor:_mediaScrollView.bottomAnchor].active = true;
    [_mediaContainerView.topAnchor constraintEqualToAnchor:_mediaScrollView.topAnchor].active = true;
    [_mediaContainerView.heightAnchor constraintEqualToAnchor:_mediaScrollView.heightAnchor].active = true;
    
    // profile picture
    self.addMediaButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.addMediaButton.frame = CGRectMake(9, 7, 40, 40);
    //self.addMediaButton.layer.cornerRadius = self.addMediaButton.frame.size.height / 2;
    [self.addMediaButton setImage:[[UIImage imageNamed:@"composeAddPicture"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.addMediaButton.layer.masksToBounds = true;
    self.addMediaButton.tintColor = [UIColor fromHex:@"9FA6AD"];
    self.addMediaButton.contentMode = UIViewContentModeScaleAspectFill;
    self.addMediaButton.adjustsImageWhenHighlighted = false;
    [self.addMediaButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.addMediaButton.transform = CGAffineTransformMakeScale(postButtonShrinkScale, postButtonShrinkScale);
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    
    [self.addMediaButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.addMediaButton.transform = CGAffineTransformMakeScale(1, 1);
        } completion:nil];
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
    
    [self.addMediaButton bk_whenTapped:^{
        [self showImagePicker];
    }];
    [self.contentView addSubview:self.addMediaButton];
    
    self.postButton = [TappableButton buttonWithType:UIButtonTypeCustom];
    self.postButton.padding = UIEdgeInsetsMake(5, 5, 5, 5);
    self.postButton.adjustsImageWhenHighlighted = false;
    self.postButton.frame = CGRectMake(self.frame.size.width - 12 - 32 - 4, _textView.frame.origin.y + 4, 32, 32);
    self.postButton.contentMode = UIViewContentModeCenter;
    [self.postButton setImage:[UIImage imageNamed:@"sendButtonIcon"] forState:UIControlStateNormal];
    [self.postButton setImage:[UIImage new] forState:UIControlStateDisabled];
    self.postButton.userInteractionEnabled = false;
    self.postButton.alpha = 0;
    self.postButton.layer.cornerRadius = 16.f;
    self.postButton.layer.shadowOpacity = 0.1f;
    self.postButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.postButton.layer.shadowOffset = CGSizeMake(0, 1);
    self.postButton.layer.shadowRadius = 3.f;
    self.postButton.transform = CGAffineTransformMakeScale(postButtonShrinkScale, postButtonShrinkScale);
    [self.postButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
            self.postButton.alpha = 0.8;
            self.postButton.transform = CGAffineTransformMakeScale(postButtonShrinkScale, postButtonShrinkScale);
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    
    [self.postButton bk_addEventHandler:^(id sender) {
        NSLog(@"cancel or drag exit");
        if (self.textView.text.length > 0 || self.media.objects.count > 0) {
            [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
                self.postButton.alpha = 1;
                self.postButton.transform = CGAffineTransformMakeScale(1, 1);
            } completion:nil];
        }
    } forControlEvents:(UIControlEventTouchCancel|UIControlEventTouchDragExit)];
    
    [self.contentView addSubview:self.postButton];
    
    self.expandButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.expandButton.adjustsImageWhenHighlighted = false;
    self.expandButton.frame = CGRectMake(self.frame.size.width - 12 - 40, _textView.frame.origin.y, 40, 40);
    self.expandButton.contentMode = UIViewContentModeCenter;
    [self.expandButton setImage:[UIImage imageNamed:@"expandComposeIcon"] forState:UIControlStateNormal];
    [self.expandButton setImage:[UIImage new] forState:UIControlStateDisabled];
    self.expandButton.userInteractionEnabled = true;
    [self.expandButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.expandButton.alpha = 0.8;
            self.expandButton.transform = CGAffineTransformMakeScale(postButtonShrinkScale, postButtonShrinkScale);
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    
    [self.expandButton bk_addEventHandler:^(id sender) {
        if (self.textView.text.length == 0 && self.media.objects.count == 0) {
            [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.expandButton.alpha = 1;
                self.expandButton.transform = CGAffineTransformMakeScale(1, 1);
            } completion:nil];
        }
    } forControlEvents:(UIControlEventTouchCancel|UIControlEventTouchDragExit)];
    
    [self.contentView insertSubview:self.expandButton belowSubview:self.postButton];
    
    self.replyingToLabel = [UIButton buttonWithType:UIButtonTypeCustom];
    self.replyingToLabel.hidden = true;
    self.replyingToLabel.frame = CGRectMake(0, 0, self.frame.size.width, 40);
    self.replyingToLabel.backgroundColor = [UIColor colorWithRed:0.98 green:0.98 blue:0.99 alpha:1.0];
    self.replyingToLabel.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    self.replyingToLabel.contentEdgeInsets = UIEdgeInsetsMake(0, 37, 0, 12);
    self.replyingToLabel.titleLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightMedium];
    [self.replyingToLabel setTitleColor:[UIColor bonfireBlack] forState:UIControlStateNormal];
    [self.replyingToLabel bk_whenTapped:^{
        [self setReplyingTo:nil];
    }];
    [self insertSubview:self.replyingToLabel belowSubview:self.contentView];
    
    UIImageView *closeIcon = [[UIImageView alloc] init];
    closeIcon.image = [[UIImage imageNamed:@"cancelReplyingToIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    closeIcon.frame = CGRectMake(self.replyingToLabel.frame.size.width - closeIcon.image.size.width - 12, self.replyingToLabel.frame.size.height / 2 - closeIcon.image.size.height / 2, closeIcon.image.size.width, closeIcon.image.size.height);
    closeIcon.tintColor = [UIColor bonfireBlack];
    closeIcon.userInteractionEnabled = true;
    closeIcon.contentMode = UIViewContentModeCenter;
    [closeIcon bk_whenTapped:^{
        [self setReplyingTo:nil];
    }];
    [self.replyingToLabel addSubview:closeIcon];
    
    UIImageView *replyIcon = [[UIImageView alloc] initWithFrame:CGRectMake(12, self.replyingToLabel.frame.size.height / 2 - 7.5, 13, 15)];
    replyIcon.image = [[UIImage imageNamed:@"postActionReply"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    replyIcon.tintColor = [UIColor bonfireBlack];
    replyIcon.contentMode = UIViewContentModeScaleAspectFill;
    [self.replyingToLabel addSubview:replyIcon];
    
    UIView *lineSeparator_t = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.replyingToLabel.frame.size.width, (1 / [UIScreen mainScreen].scale))];
    lineSeparator_t.backgroundColor = [UIColor colorWithWhite:0 alpha:0.06];
    [self.replyingToLabel addSubview:lineSeparator_t];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (defaultPlaceholder == nil || mediaPlaceholder == nil) {
        [self updatePlaceholders];
    }
    
    self.replyingToLabel.frame = CGRectMake(0, self.replyingToLabel.frame.origin.y, self.frame.size.width, 40);
    
    // style
    // -- text view
    [self resize:false];
}

- (Post *)createPostObject {
    Post *post = [[Post alloc] init];
    
    NSString *message = self.textView.text;
    
    post.type = @"post";
    post.tempId = [NSString stringWithFormat:@"%d", [Session getTempId]];
    // TODO: Add support for images
    
    PostAttributes *attributes = [[PostAttributes alloc] init];
    /*
     @property (nonatomic) PostDetails *details;
     @property (nonatomic) PostStatus *status;
     @property (nonatomic) PostSummaries *summaries;
     @property (nonatomic) PostContext *context;
     */
    PostDetails *details = [[PostDetails alloc] init];
    details.creator = [Session sharedInstance].currentUser;
    if (message.length > 0) {
        details.message = message;
    }
    attributes.details = details;
    
    PostStatus *status = [[PostStatus alloc] init];
    
    NSDate *date = [NSDate new];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    status.createdAt = [dateFormatter stringFromDate:date];
    attributes.status = status;
    
    post.attributes = attributes;
    
    return post;
}

- (void)setMediaTypes:(NSArray *)mediaTypes {
    if (mediaTypes != _mediaTypes) {
        _mediaTypes = mediaTypes;
        
        [self updateMediaAvailability];
    }
}

- (void)updatePlaceholders {
    NSString *publicPostPlaceholder = @"Share with everyone...";
    
    defaultPlaceholder = @"";
    UIViewController *parentController = UIViewParentController(self);
    if (self.replyingTo != nil) {
        if ([self.replyingTo.attributes.details.creator.identifier isEqualToString:[Session sharedInstance].currentUser.identifier]) {
            defaultPlaceholder = @"Add something new...";
        }
        else {
            NSString *creatorIdentifier = self.replyingTo.attributes.details.creator.attributes.details.identifier;
            defaultPlaceholder = creatorIdentifier ? [NSString stringWithFormat:@"Reply to @%@...", creatorIdentifier] : @"Add a reply...";
        }
    }
    else if ([parentController isKindOfClass:[ProfileViewController class]]) {
        ProfileViewController *parentProfile = (ProfileViewController *)parentController;
        if ([parentProfile.user.identifier isEqualToString:[Session sharedInstance].currentUser.identifier] || [self.textView isFirstResponder]) {
            // me
            defaultPlaceholder = publicPostPlaceholder;
        }
        else {
            defaultPlaceholder = [NSString stringWithFormat:@"Share with @%@", parentProfile.user.attributes.details.identifier];
        }
    }
    else if ([parentController isKindOfClass:[CampViewController class]]) {
        CampViewController *parentCamp = (CampViewController *)parentController;
        if (parentCamp.camp == nil) {
            defaultPlaceholder = publicPostPlaceholder;
        }
        else {
            if (parentCamp.camp.attributes.details.title == nil) {
                defaultPlaceholder = @"Share something...";
            }
            else {
                defaultPlaceholder = [[Session sharedInstance].defaults.post.composePrompt stringByReplacingOccurrencesOfString:@"{group_name}" withString:parentCamp.camp.attributes.details.title];
            }
        }
    }
    else if ([parentController isKindOfClass:[PostViewController class]]) {
        defaultPlaceholder = @"Add a reply...";
    }
    defaultPlaceholder = [self stringByDeletingWordsFromString:defaultPlaceholder toFit:CGRectMake(0, 0, self.textView.frame.size.width - 44 - 14 - 14, self.textView.frame.size.height - self.textView.contentInset.top - self.textView.contentInset.bottom) withInset:0 usingFont:self.textView.font];
    
    mediaPlaceholder = @"Add caption or Share";
    
    if (self.media.objects.count == 0) {
        self.textView.placeholder = defaultPlaceholder;
    }
    else {
        self.textView.placeholder = mediaPlaceholder;
    }
}

- (NSString *)stringByDeletingWordsFromString:(NSString *)string
                                        toFit:(CGRect)rect
                                    withInset:(CGFloat)inset
                                    usingFont:(UIFont *)font
{
    NSString *result = [[string copy] stringByReplacingOccurrencesOfString:@"..." withString:@""];
    CGSize maxSize = CGSizeMake(rect.size.width  - (inset * 2), FLT_MAX);
    if (!font) font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    CGRect boundingRect = [result boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: font, } context:nil];
    CGSize size = boundingRect.size;
    NSRange range;
    
    if (rect.size.height < size.height) {
        while (rect.size.height < size.height) {
            
            range = [result rangeOfString:@" "
                                  options:NSBackwardsSearch];
            
            if (range.location != NSNotFound && range.location > 0 ) {
                result = [result substringToIndex:range.location];
            } else {
                result = [result substringToIndex:result.length - 1];
            }
            
            if (!font) font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
            CGRect boundingRect = [result boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: font, } context:nil];
            size = boundingRect.size;
        }
    }

    if (result.length < string.length) {
        result = [result stringByAppendingString:@"..."];
    }
    
    return result;
}

- (void)reset {
    self.textView.text = @"";
    [self hidePostButton];
    [self.textView resignFirstResponder];
    [self.media flush];
    [self hideMediaTray];
    [self setReplyingTo:nil];
    [self updateMediaAvailability];
}

- (void)setActive:(BOOL)isActive {
    //CGRect screenRect = [[UIScreen mainScreen] bounds];
    //CGFloat screenWidth = screenRect.size.width;
    _active = isActive;
    // NSLog(@"active has been set to %@", (isActive ? @"TRUE" : @"FALSE"));
    if (isActive) {
        [self.textView becomeFirstResponder];
    }
    else {
        [self.textView resignFirstResponder];
    }
}

- (BOOL)active {
    return _active;
}
- (BOOL)isActive {
    return _active;
}

- (void)resize:(BOOL)animated {
    CGRect textViewRect = [self.textView.text.length == 0 ? @"Quintessential" : self.textView.text boundingRectWithSize:CGSizeMake(self.textView.frame.size.width - self.textView.textContainerInset.left - self.textView.textContainerInset.right, 800) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.textView.font} context:nil];
    
    CGFloat textHeight = ceil(textViewRect.size.height) + self.textView.textContainerInset.top + self.textView.textContainerInset.bottom;
    
    CGFloat textViewPadding = self.textView.frame.origin.y;
    
    CGFloat bottomPadding = [[[UIApplication sharedApplication] delegate] window].safeAreaInsets.bottom;
    CGFloat barHeight = textViewPadding + textHeight + textViewPadding + bottomPadding;
    
    CGRect frame = self.frame;
    CGFloat bottomY = frame.origin.y + frame.size.height;
    
    [UIView animateWithDuration:animated?0.6:0 delay:0 usingSpringWithDamping:0.75f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.frame = CGRectMake(frame.origin.x, bottomY - barHeight, frame.size.width, barHeight);
        self.contentView.frame = self.bounds;
        self.textView.frame = CGRectMake(self.textView.frame.origin.x, self.textView.frame.origin.y, self.textView.frame.size.width, textHeight);
        
        self.postButton.center = CGPointMake(self.textView.frame.origin.x + self.textView.frame.size.width - 20, self.textView.frame.origin.y + self.textView.frame.size.height - 20);
        self.expandButton.center = self.postButton.center;
        
        self.addMediaButton.frame = CGRectMake(self.addMediaButton.frame.origin.x, self.frame.size.height - self.addMediaButton.frame.size.height - (self.textView.frame.origin.y + ((40 - self.addMediaButton.frame.size.height) / 2)) - bottomPadding, self.addMediaButton.frame.size.width, self.addMediaButton.frame.size.height);
    } completion:nil];
}

- (void)showPostButton {
    self.postButton.userInteractionEnabled = true;
    self.expandButton.userInteractionEnabled = false;
    
    if (self.postButton.alpha == 0) {
        self.postButton.transform = CGAffineTransformMakeScale(postButtonShrinkScale / 2, postButtonShrinkScale / 2);
    }
    
    [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.postButton.transform = CGAffineTransformMakeScale(1, 1);
        self.postButton.alpha = 1;
        
        self.expandButton.transform = CGAffineTransformMakeScale(postButtonShrinkScale / 2, postButtonShrinkScale / 2);
        self.expandButton.alpha = 0;
    } completion:nil];
}
- (void)hidePostButton {
    self.postButton.userInteractionEnabled = false;
    self.expandButton.userInteractionEnabled = true;
    
    [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.postButton.transform = CGAffineTransformMakeScale(postButtonShrinkScale / 2, postButtonShrinkScale / 2);
        self.postButton.alpha = 0;
        
        self.expandButton.transform = CGAffineTransformMakeScale(1, 1);
        self.expandButton.alpha = 1;
    } completion:nil];
}

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}
    
- (void)showImagePicker {
    UIAlertController *imagePickerOptions = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *takePhoto = [UIAlertAction actionWithTitle:@"Take Photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self takePhotoForProfilePicture:nil];
    }];
    [imagePickerOptions addAction:takePhoto];
    
    UIAlertAction *chooseFromLibrary = [UIAlertAction actionWithTitle:@"Choose from Library" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self chooseFromLibraryForProfilePicture:nil];
    }];
    [imagePickerOptions addAction:chooseFromLibrary];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    [imagePickerOptions addAction:cancel];
    
    [UIViewParentController(self) presentViewController:imagePickerOptions animated:YES completion:nil];
}
    
    
- (void)takePhotoForProfilePicture:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    [UIViewParentController(self) presentViewController:picker animated:YES completion:nil];
}
- (void)chooseFromLibraryForProfilePicture:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [UIViewParentController(self) presentViewController:picker animated:YES completion:nil];
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    NSLog(@"didFinishPickingMediaWithInfo");
    // determine file type
    PHAsset *asset = info[UIImagePickerControllerPHAsset];
    if (asset) {
        NSLog(@"asset:D");
        [self.media addAsset:asset];
    }
    else {
        NSLog(@"image:D");
        UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
        [self.media addImage:chosenImage];
    }
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    [_textView becomeFirstResponder];
}

- (void)mediaObjectAdded:(BFMediaObject *)object {
    NSLog(@"media object added:: %@", object);
    [self showMediaTray];
    
    NSData *data = object.data;
    
    SDAnimatedImageView *view = [[SDAnimatedImageView alloc] init];
    view.userInteractionEnabled = true;
    view.backgroundColor = [UIColor blueColor];
    view.layer.cornerRadius = 14.f;
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
    view.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.06f].CGColor;
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
    
    [self updateMediaAvailability];
    
    [self.mediaScrollView setContentOffset:CGPointMake(self.mediaScrollView.contentSize.width - self.mediaScrollView.frame.size.width, 0)];
}

- (void)removeImageAtIndex:(NSInteger)index {
    if (self.media.objects.count > index) {
        BFMediaObject *object = [self.media.objects objectAtIndex:index];
        
        [self.media removeObject:object];
    }
    
    if (self.mediaContainerView.subviews.count > index) {
        UIView *view = [self.mediaContainerView.subviews objectAtIndex:index];
    
        view.userInteractionEnabled = false;
        
        [self updateMediaAvailability];
        if (self.media.objects.count == 0) {
            // no items left
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self hideMediaTray];
            });
        }
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            view.transform = CGAffineTransformMakeScale(0.6, 0.6);
            view.alpha = 0.01;
        } completion:^(BOOL finished) {
        }];
        [UIView animateWithDuration:0.4f delay:0.15 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            view.hidden = true;
        } completion:^(BOOL finished) {
            [view removeFromSuperview];
        }];
    }
}

- (void)updateMediaAvailability {
    NSLog(@"self.media canAddImages? %@", [self.media canAddImage] ? @"YES" : @"NO");
    NSLog(@"self.media canAddGIFs? %@", [self.media canAddGIF] ? @"YES" : @"NO");
    NSLog(@"self.media canAddMedia? %@", [self.media canAddMedia] ? @"YES" : @"NO");
    
    self.addMediaButton.hidden = false;
    self.addMediaButton.enabled = [self.media canAddMedia];
    [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.addMediaButton.alpha = (self.addMediaButton.enabled ? 1 : 0.25);
    } completion:nil];
    
    /*
    if ([self.mediaTypes containsObject:BFMediaTypeImage] ||
        [self.mediaTypes containsObject:BFMediaTypeGIF]) {
        // determine add media button
        self.addMediaButton.hidden = false;
        self.addMediaButton.enabled = (self.media.count < self.maxImages);
        
        [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.addMediaButton.alpha = (self.addMediaButton.enabled ? 1 : 0.25);
        } completion:nil];
        
        if ([self.mediaTypes containsObject:BFMediaTypeText]) {
            self.textView.frame = CGRectMake(TEXT_VIEW_WITH_IMAGE_X, self.textView.frame.origin.y, self.frame.size.width - TEXT_VIEW_WITH_IMAGE_X - 12, self.textView.frame.size.height);
        }
        else {
            
        }
    }
    else {
        self.addMediaButton.hidden = true;
        
        self.textView.frame = CGRectMake(TEXT_VIEW_WITHOUT_IMAGE_X, self.textView.frame.origin.y, self.frame.size.width - TEXT_VIEW_WITHOUT_IMAGE_X - 12, self.textView.frame.size.height);
    }*/
    
    [self resize:false];
}
    
- (void)showMediaTray {
    _textView.textContainerInset = UIEdgeInsetsMake(9 + 140, _textView.textContainerInset.left, _textView.textContainerInset.bottom, _textView.textContainerInset.right);
    _textView.placeholder = @"Add caption or Share";
    
    [self resize:false];
    [self showPostButton];
    
    self.mediaScrollView.alpha = 1;
    self.mediaLineSeparator.alpha = 1;
    self.mediaScrollView.hidden = false;
    self.mediaLineSeparator.hidden = false;
    self.mediaScrollView.userInteractionEnabled = true;
    self.mediaLineSeparator.userInteractionEnabled = true;
}
- (void)hideMediaTray {
    _textView.textContainerInset = UIEdgeInsetsMake(9, _textView.textContainerInset.left, _textView.textContainerInset.bottom, _textView.textContainerInset.right);
    _textView.placeholder = defaultPlaceholder;
    
    [self resize:true];
    if (self.textView.text.length == 0) {
        [self hidePostButton];
    }
    
    self.mediaScrollView.userInteractionEnabled = false;
    self.mediaLineSeparator.userInteractionEnabled = false;
    [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.mediaScrollView.alpha = 0;
        self.mediaLineSeparator.alpha = 0;
    } completion:^(BOOL finished) {
        self.mediaScrollView.hidden = true;
        self.mediaLineSeparator.hidden = true;
    }];
    
    // remove all media views
    for (UIView *subview in self.mediaContainerView.subviews) {
        [subview removeFromSuperview];
    }
}

- (void)setReplyingTo:(Post *)replyingTo {
    if (replyingTo != _replyingTo) {
        _replyingTo = replyingTo;
        
        if (_replyingTo) {
            if ([replyingTo.attributes.details.creator.identifier isEqualToString:[Session sharedInstance].currentUser.identifier]) {
                [_replyingToLabel setTitle:@"Replying to yourself" forState:UIControlStateNormal];
            }
            else {
                [_replyingToLabel setTitle:[NSString stringWithFormat:@"Replying to @%@", replyingTo.attributes.details.creator.attributes.details.identifier] forState:UIControlStateNormal];
            }
            [self showReplyingTo];
        }
        else {
            self.textView.text = @"";
            [self hideReplyingTo];
        }
        
        [self updatePlaceholders];
    }
}
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    CGPoint translatedPoint = [_replyingToLabel convertPoint:point fromView:self];
    
    if (!_replyingToLabel.isHidden && CGRectContainsPoint(_replyingToLabel.bounds, translatedPoint)) {
        return [_replyingToLabel hitTest:translatedPoint withEvent:event];
    }
    return [super hitTest:point withEvent:event];
    
}

- (void)showReplyingTo {
    self.replyingToLabel.hidden = false;
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.replyingToLabel.frame = CGRectMake(0, -1 * self.replyingToLabel.frame.size.height, self.frame.size.width, self.replyingToLabel.frame.size.height);
    } completion:nil];
}
- (void)hideReplyingTo {
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.replyingToLabel.frame = CGRectMake(0, 0, self.frame.size.width, self.replyingToLabel.frame.size.height);
    } completion:^(BOOL finished) {
        self.replyingToLabel.hidden = true;
    }];
}

@end
