//
//  PostCell.m
//  Pulse
//
//  Created by Austin Valleskey on 3/10/18.
//  Copyright © 2018 Ingenious, Inc. All rights reserved.
//

#import "BubblePostCell.h"
#import <BlocksKit/BlocksKit+UIKit.h>
#import <SafariServices/SafariServices.h>
#import <HapticHelper/HapticHelper.h>
#import "Session.h"
#import "ComplexNavigationController.h"
#import "Launcher.h"
#import "UIColor+Palette.h"
#import <Tweaks/FBTweakInline.h>

#define UIViewParentController(__view) ({ \
    UIResponder *__responder = __view; \
    while ([__responder isKindOfClass:[UIView class]]) \
    __responder = [__responder nextResponder]; \
    (UIViewController *)__responder; \
    })

@implementation BubblePostCell {
    CGPoint originalCenter;
    BOOL isLeftSwipeSuccessful;
    BOOL isRightSwipeSuccessful;
    UIPanGestureRecognizer *panRecognizer;
    UIColor *sparkColor;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.selectable = true;
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenRect.size.width;
        
        self.contentView.frame = CGRectMake(0, 0, screenWidth, 100);
        self.contentView.backgroundColor = [UIColor whiteColor];
        self.contentView.layer.shadowRadius = 1.f;
        self.contentView.layer.shadowColor = [UIColor blackColor].CGColor;
        self.contentView.layer.shadowOpacity = 0;
        self.contentView.layer.shadowOffset = CGSizeMake(0, 0);
        
        self.post = [[Post alloc] init];
        
        self.leftBar = [[UIView alloc] initWithFrame:CGRectMake(-3, 6, 6, self.frame.size.height - 12)];
        self.leftBar.hidden = true;
        self.leftBar.layer.cornerRadius = 4.f;
        [self.contentView addSubview:self.leftBar];
        
        self.profilePicture = [[UIImageView alloc] initWithFrame:CGRectMake(12, 10, 42, 42)];
        BOOL circleProfilePictures = FBTweakValue(@"Post", @"General", @"Circle Profile Pictures", NO);
        if (circleProfilePictures) {
            [self continuityRadiusForView:self.profilePicture withRadius:self.profilePicture.frame.size.height*.5];
        }
        else {
            [self continuityRadiusForView:self.profilePicture withRadius:self.profilePicture.frame.size.height*.25];
        }
        [self.profilePicture setImage:[[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        self.profilePicture.layer.masksToBounds = true;
        self.profilePicture.backgroundColor = [UIColor whiteColor];
        self.profilePicture.userInteractionEnabled = true;
        [self.contentView addSubview:self.profilePicture];
        
        self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(postContentOffset.left + 4, postContentOffset.top, self.contentView.frame.size.width - (postContentOffset.left + 4) - postContentOffset.right, 16)];
        self.nameLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightBold];
        self.nameLabel.textAlignment = NSTextAlignmentLeft;
        self.nameLabel.text = @"Display Name";
        self.nameLabel.textColor = [UIColor colorWithWhite:0.27f alpha:1];
        [self.contentView addSubview:self.nameLabel];
        
        self.usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.nameLabel.frame.origin.x, self.nameLabel.frame.origin.y + self.nameLabel.frame.size.height, self.nameLabel.frame.size.width, 15)];
        self.usernameLabel.font = [UIFont systemFontOfSize:13.f weight:UIFontWeightRegular];
        self.usernameLabel.textAlignment = NSTextAlignmentLeft;
        self.usernameLabel.text = @"@username";
        self.usernameLabel.textColor = [UIColor colorWithWhite:0.6f alpha:1];
        //[self.contentView addSubview:self.usernameLabel];
        
        self.sparked = false;
        self.sparkedIcon = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width, self.nameLabel.frame.origin.y, 20, self.nameLabel.frame.size.height)];
        self.sparkedIcon.contentMode = UIViewContentModeCenter;
        self.sparkedIcon.alpha = 0;
        if ([[Session sharedInstance].defaults.post.displayVote.icon isEqualToString:@"star"]) {
            [self.sparkedIcon setImage:[[UIImage imageNamed:@"cellIndicatorStar"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        }
        else if ([[Session sharedInstance].defaults.post.displayVote.icon isEqualToString:@"heart"]) {
            [self.sparkedIcon setImage:[[UIImage imageNamed:@"cellIndicatorHeart"]imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        }
        else if ([[Session sharedInstance].defaults.post.displayVote.icon isEqualToString:@"thumb"]) {
            [self.sparkedIcon setImage:[[UIImage imageNamed:@"cellIndicatorThumb"]imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        }
        else if ([[Session sharedInstance].defaults.post.displayVote.icon isEqualToString:@"flame"]) {
            [self.sparkedIcon setImage:[[UIImage imageNamed:@"cellIndicatorFlame"]imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        }
        else {
            [self.sparkedIcon setImage:[[UIImage imageNamed:@"cellIndicatorBolt"]imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        }
        self.sparkedIcon.tintColor = [UIColor colorWithWhite:0.6f alpha:1];
        self.sparkedIcon.frame = CGRectMake(self.sparkedIcon.frame.origin.x, self.sparkedIcon.frame.origin.y, self.sparkedIcon.image.size.width, self.sparkedIcon.frame.size.height);
        [self.contentView addSubview:self.sparkedIcon];
        
        self.moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.moreButton setImage:[UIImage imageNamed:@"moreIcon"] forState:UIControlStateNormal];
        self.moreButton.frame = CGRectMake(self.frame.size.width - 42 + 12, postContentOffset.top + (self.nameLabel.frame.size.height / 2) - 20, 42, 40); // result should be 8
        //[self.contentView addSubview:self.moreButton];
        
        // text view
        self.textView = [[PostTextView alloc] initWithFrame:CGRectMake(postContentOffset.left, 58, self.contentView.frame.size.width - postContentOffset.right - postContentOffset.left, 200)]; // 58 will change based on whether or not the detail label is shown
        self.textView.textView.textContainerInset = postTextViewInset;
        self.textView.textView.font = textViewFont;
        self.textView.textView.editable = false;
        self.textView.textView.selectable = false;
        [self.contentView addSubview:self.textView];
        
        // image view
        self.pictureView = [[UIImageView alloc] initWithFrame:CGRectMake(self.textView.frame.origin.x, 56, self.textView.frame.size.width, [Session sharedInstance].defaults.post.imgHeight)];
        self.pictureView.backgroundColor = [UIColor colorWithRed:0.92 green:0.93 blue:0.94 alpha:1.0];
        self.pictureView.layer.cornerRadius = self.textView.textView.layer.cornerRadius;
        self.pictureView.layer.masksToBounds = true;
        self.pictureView.contentMode = UIViewContentModeScaleAspectFill;
        self.pictureView.layer.masksToBounds = true;
        self.pictureView.userInteractionEnabled = true;
        [self.contentView addSubview:self.pictureView];
        
        self.urlPreviewView = [[PostURLPreviewView alloc] initWithFrame:CGRectMake(self.textView.frame.origin.x, 0, self.textView.frame.size.width, [Session sharedInstance].defaults.post.imgHeight)];
        self.urlPreviewView.backgroundColor = [UIColor colorWithRed:0.92 green:0.93 blue:0.94 alpha:1.0];
        self.urlPreviewView.layer.cornerRadius = self.textView.textView.layer.cornerRadius;
        self.urlPreviewView.layer.masksToBounds = true;
        [self.contentView addSubview:self.urlPreviewView];
        
        self.detailsLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.nameLabel.frame.origin.x, self.textView.frame.origin.y + self.textView.frame.size.height + 8, self.nameLabel.frame.size.width, 15)];
        self.detailsLabel.font = [UIFont systemFontOfSize:12.f weight:UIFontWeightRegular];
        self.detailsLabel.textAlignment = NSTextAlignmentLeft;
        self.detailsLabel.text = @"4h";
        self.detailsLabel.textColor = [UIColor colorWithWhite:0.47f alpha:1];
        [self.contentView addSubview:self.detailsLabel];
        
        self.lineSeparator = [[UIView alloc] init];
        self.lineSeparator.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1];
        [self addSubview:self.lineSeparator];
        
        [self initalizePan];
        [self initalizeLongPress];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.frame.origin.x == 0) {
        // --- DATA ---
        // line separator
        self.lineSeparator.frame = CGRectMake(0, self.frame.size.height - (1 / [UIScreen mainScreen].scale), self.frame.size.width, 1 / [UIScreen mainScreen].scale);
        
        CGRect nameLabelRect = [self.nameLabel.attributedText boundingRectWithSize:CGSizeMake(self.nameLabel.frame.size.width, 1200) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil];
        self.nameLabel.frame = CGRectMake(self.nameLabel.frame.origin.x, self.nameLabel.frame.origin.y, self.nameLabel.frame.size.width, nameLabelRect.size.height);
        self.usernameLabel.frame = CGRectMake(self.usernameLabel.frame.origin.x, self.nameLabel.frame.origin.y + self.nameLabel.frame.size.height + 2, self.usernameLabel.frame.size.width, self.usernameLabel.frame.size.height);
        self.sparkedIcon.frame = CGRectMake(self.bounds.size.width - (self.sparked ? postContentOffset.right + self.sparkedIcon.frame.size.width : 0), self.sparkedIcon.frame.origin.y, self.sparkedIcon.frame.size.width, self.sparkedIcon.frame.size.height);
        
        // style
        // -- post type [new, trending, pinned, n.a.]
        NSString *post_type = @"";
        self.leftBar.frame = CGRectMake(-4, self.profilePicture.frame.origin.y + (self.profilePicture.frame.size.height / 2) - 4, 8, 8);
        if ([post_type isEqualToString:@"trending_post"]) {
            self.leftBar.hidden = false;
            self.leftBar.backgroundColor = [UIColor colorWithDisplayP3Red:0.96 green:0.54 blue:0.14 alpha:1.0];
            //self.backgroundColor = [UIColor colorWithRed:1.00 green:0.98 blue:0.96 alpha:1.0];
        }
        else if ([post_type isEqualToString:@"new_post"]) {
            self.leftBar.hidden = false;
            self.leftBar.backgroundColor = [UIColor colorWithDisplayP3Red:0.00 green:0.46 blue:1.00 alpha:1.0];
            self.backgroundColor = [UIColor colorWithRed:0.95 green:0.97 blue:1.00 alpha:1.0];
        }
        else if ([post_type isEqualToString:@"pinned_post"]) {
            self.leftBar.hidden = false;
            self.leftBar.backgroundColor = [UIColor colorWithDisplayP3Red:0.87 green:0.09 blue:0.09 alpha:1.0];
            self.backgroundColor = [UIColor colorWithRed:0.99 green:0.95 blue:0.95 alpha:1.0];
        }
        else {
            self.leftBar.hidden = true;
            self.backgroundColor = [UIColor whiteColor];
        }
        
        // -- text view
        [self.textView resize];
        self.textView.frame = CGRectMake(self.textView.frame.origin.x, self.nameLabel.frame.origin.y + self.nameLabel.frame.size.height + 4, self.textView.frame.size.width, self.textView.frame.size.height);
        self.textView.tintColor = self.tintColor;
        
        self.moreButton.frame = CGRectMake(self.frame.size.width - self.moreButton.frame.size.width, self.moreButton.frame.origin.y, self.moreButton.frame.size.width, self.moreButton.frame.size.height);
        
        BOOL hasImage = FBTweakValue(@"Post", @"General", @"Show Image", NO); //self.post.images != nil && self.post.images.count > 0;
        if (hasImage) {
            self.urlPreviewView.hidden = true;
            
            self.pictureView.hidden = false;
            self.pictureView.frame = CGRectMake(self.pictureView.frame.origin.x, self.textView.frame.origin.y + self.textView.frame.size.height + 4, self.pictureView.frame.size.width, self.pictureView.frame.size.height);
            //[self.pictureView sd_setImageWithURL:[NSURL URLWithString:self.post.images[0]]];
            
            // -- details
            self.detailsLabel.frame = CGRectMake(self.detailsLabel.frame.origin.x, self.pictureView.frame.origin.y + self.pictureView.frame.size.height + 8, self.detailsLabel.frame.size.width, self.detailsLabel.frame.size.height);
        }
        else {
            if ([self.post requiresURLPreview]) {
                self.urlPreviewView.hidden = false;
                
                self.urlPreviewView.frame = CGRectMake(self.urlPreviewView.frame.origin.x, self.textView.frame.origin.y + self.textView.frame.size.height + 10, self.urlPreviewView.frame.size.width, self.urlPreviewView.frame.size.height);
            }
            else {
                self.urlPreviewView.hidden = true;
            }
            
            self.pictureView.hidden = true;
            
            // -- details
            self.detailsLabel.frame = CGRectMake(self.detailsLabel.frame.origin.x, self.textView.frame.origin.y + self.textView.frame.size.height + 4, self.detailsLabel.frame.size.width, self.detailsLabel.frame.size.height);
        }
        
        self.sparkIndicator.frame = CGRectMake(self.sparkIndicator.frame.origin.x, self.frame.size.height / 2 - (self.sparkIndicator.frame.size.height / 2), self.sparkIndicator.frame.size.width, self.sparkIndicator.frame.size.height);
        self.replyIndicator.frame = CGRectMake(self.frame.size.width + 16, self.frame.size.height / 2 - (self.replyIndicator.frame.size.height / 2), self.replyIndicator.frame.size.width, self.replyIndicator.frame.size.height);
        self.replyIndicator.backgroundColor = [UIColor clearColor];
        
        // [self continuityRadiusForView:self.contentView withRadius:12.f];
    }
}

// Pan gesture recognizer for left and right swipes
- (void)initalizePan {
    panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    panRecognizer.delegate = self;
    [self addGestureRecognizer:panRecognizer];
    
    UIColor *defaultBackgroundColor = [UIColor colorWithWhite:0.47f alpha:1];
    
    self.sparkIndicator = [[UIImageView alloc] initWithFrame:CGRectMake(-44 - 16, (self.frame.size.height / 2) - 22, 44, 44)];
    self.sparkIndicator.layer.cornerRadius = self.sparkIndicator.frame.size.height / 2;
    self.sparkIndicator.layer.masksToBounds = true;
    self.sparkIndicator.contentMode = UIViewContentModeScaleAspectFill;
    if ([[Session sharedInstance].defaults.post.displayVote.icon isEqualToString:@"star"]) {
        [self.sparkIndicator setImage:[[UIImage imageNamed:@"cellSwipeStar"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        self.sparkIndicator.backgroundColor = [UIColor colorWithDisplayP3Red:0.99 green:0.58 blue:0.12 alpha:1.0];
    }
    else if ([[Session sharedInstance].defaults.post.displayVote.icon isEqualToString:@"heart"]) {
        [self.sparkIndicator setImage:[[UIImage imageNamed:@"cellSwipeHeart"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        self.sparkIndicator.backgroundColor = [UIColor colorWithDisplayP3Red:0.89 green:0.10 blue:0.13 alpha:1.0];
    }
    else if ([[Session sharedInstance].defaults.post.displayVote.icon isEqualToString:@"thumb"]) {
        [self.sparkIndicator setImage:[[UIImage imageNamed:@"cellSwipeThumb"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        self.sparkIndicator.backgroundColor = [UIColor colorWithDisplayP3Red:0.00 green:0.46 blue:1.00 alpha:1.0];
    }
    else if ([[Session sharedInstance].defaults.post.displayVote.icon isEqualToString:@"flame"]) {
        [self.sparkIndicator setImage:[[UIImage imageNamed:@"cellSwipeFlame"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        self.sparkIndicator.backgroundColor = [UIColor colorWithDisplayP3Red:0.99 green:0.42 blue:0.12 alpha:1.0];
    }
    else {
        [self.sparkIndicator setImage:[[UIImage imageNamed:@"cellSwipeBolt"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        self.sparkIndicator.backgroundColor = [UIColor bonfireRed];
    }
    sparkColor = self.sparkIndicator.backgroundColor;
    
    UIColor *sparkDefaultTintColor = self.sparked ? sparkColor : defaultBackgroundColor;
    UIColor *sparkDefaultBackgroundColor = self.sparked ? [UIColor whiteColor] : [UIColor clearColor];
    self.sparkIndicator.tintColor = sparkDefaultTintColor;
    self.sparkIndicator.backgroundColor = sparkDefaultBackgroundColor;
    
    [self addSubview:self.sparkIndicator];
    
    self.replyIndicator = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width + 16, (self.frame.size.height / 2) - 22, 44, 44)];
    self.replyIndicator.layer.cornerRadius = self.replyIndicator.frame.size.height / 2;
    self.replyIndicator.layer.masksToBounds = true;
    self.replyIndicator.tintColor = defaultBackgroundColor;
    self.replyIndicator.backgroundColor = [UIColor clearColor];
    self.replyIndicator.contentMode = UIViewContentModeCenter;
    [self.replyIndicator setImage:[[[UIImage imageNamed:@"cellSwipeShare"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] imageWithAlignmentRectInsets:UIEdgeInsetsMake(-1, 0, 0, 0)]];
    [self addSubview:self.replyIndicator];
}
- (void)initalizeLongPress {
    UIGestureRecognizer *gestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget: self
                                                                                           action: @selector(cellLongPressed:)];
    [self addGestureRecognizer:gestureRecognizer];
}
- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        originalCenter = recognizer.view.center;
        // UIColor *color = sparkColor;
        
        self.layer.zPosition = self.layer.zPosition + 1;
        
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.contentView.layer.shadowOpacity = 0.1f;
            self.contentView.layer.cornerRadius = 4.f;
        } completion:nil];
    }
    
    if (recognizer.state == UIGestureRecognizerStateChanged) {
        [self checkIfSwiped:recognizer];
    }
    
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        CGRect originalFrame = CGRectMake(0, recognizer.view.frame.origin.y, recognizer.view.bounds.size.width, recognizer.view.bounds.size.height);
        if (isLeftSwipeSuccessful) {
            // NSLog(@"self sparked? %@", self.sparked ? @"YES" : @"NO");
            [self setSparked:!self.sparked withAnimation:YES];
            
            if (self.sparked) {
                // not sparked -> spark it
                [[Session sharedInstance] sparkPost:self.post completion:^(BOOL success, id responseObject) {
                    if (success) {
                        // NSLog(@"success upvoting!");
                    }
                }];
            }
            else {
                // not sparked -> spark it
                [[Session sharedInstance] unsparkPost:self.post completion:^(BOOL success, id responseObject) {
                    if (success) {
                        // NSLog(@"success downvoting.");
                    }
                }];
            }
        }
        if (isRightSwipeSuccessful) {
            [self showSharePostSheet];
        }
        [self moveViewBackIntoPlace:originalFrame];
        
        self.layer.zPosition = self.layer.zPosition - 1;
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.contentView.layer.shadowOpacity = 0;
            self.contentView.layer.cornerRadius = 0;
        } completion:nil];
    }
}
- (void)checkIfSwiped:(UIPanGestureRecognizer *)recognizer {
    CGPoint translation = [recognizer translationInView:self];
    CGPoint center = CGPointMake(originalCenter.x + translation.x, originalCenter.y);
    self.center = center;
    isLeftSwipeSuccessful = self.frame.origin.x > self.frame.size.width / 3;
    isRightSwipeSuccessful = self.frame.origin.x < (self.frame.size.width / 3) * -1;
    
    UIColor *defaultBackgroundColor = [UIColor colorWithWhite:0.47f alpha:1];
    
    UIColor *sparkDefaultTintColor = self.sparked ? sparkColor : defaultBackgroundColor;
    UIColor *sparkDefaultBackgroundColor = self.sparked ? [UIColor whiteColor] : [UIColor clearColor];
    
    UIColor *sparkSuccessTintColor = self.sparked ? defaultBackgroundColor : sparkColor;
    UIColor *sparkSuccessBackgroundColor = self.sparked ? [UIColor clearColor] : [UIColor whiteColor];
    
    if (isLeftSwipeSuccessful && self.contentView.tag != 1) {
        self.contentView.tag = 1;
        // UIColor *color = sparkColor;
        
        [HapticHelper generateFeedback:FeedbackType_Impact_Medium];
        [UIView animateWithDuration:0.15f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            // self.contentView.backgroundColor = self.sparked ? [UIColor colorWithWhite:0 alpha:0.04f] : [color colorWithAlphaComponent:0.06f];
            
            self.sparkIndicator.tintColor = sparkSuccessTintColor;
            self.sparkIndicator.backgroundColor = sparkSuccessBackgroundColor;
        } completion:nil];
        
        [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            self.sparkIndicator.transform = CGAffineTransformMakeScale(1.2, 1.2);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                self.sparkIndicator.transform = CGAffineTransformIdentity;
            } completion:nil];
        }];
    }
    if (isRightSwipeSuccessful && self.contentView.tag != 2) {
        self.contentView.tag = 2;
        [HapticHelper generateFeedback:FeedbackType_Impact_Light];
        [UIView animateWithDuration:0.15f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            // self.contentView.backgroundColor = [self.tintColor colorWithAlphaComponent:0.06f];
            
            self.replyIndicator.tintColor = self.tintColor;
            self.replyIndicator.backgroundColor = [UIColor whiteColor];
        } completion:nil];
        
        [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            self.replyIndicator.transform = CGAffineTransformMakeScale(1.2, 1.2);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                self.replyIndicator.transform = CGAffineTransformIdentity;
            } completion:nil];
        }];
    }
    
    if ((!isLeftSwipeSuccessful && self.contentView.tag == 1) || (!isRightSwipeSuccessful && self.contentView.tag == 2)) {
        self.contentView.tag = 0;
        
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
           //  self.contentView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.04f];
            
            self.sparkIndicator.tintColor = sparkDefaultTintColor;
            self.sparkIndicator.backgroundColor = sparkDefaultBackgroundColor;
            
            self.replyIndicator.tintColor = defaultBackgroundColor;
            self.replyIndicator.backgroundColor = [UIColor clearColor];
        } completion:nil];
    }
    
}
- (void)moveViewBackIntoPlace:(CGRect)originalFrame {
    [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.frame = originalFrame;
    } completion:nil];
}
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        UIPanGestureRecognizer *panGestureRecognizer = (UIPanGestureRecognizer *)gestureRecognizer;
        
        CGPoint translation = [panGestureRecognizer translationInView:self];
        if (fabs(translation.x) > fabs(translation.y)) {
            return true;
        }
    }
    
    return false;
}

- (void)cellLongPressed:(id)sender {
    [self openPostActions];
}
- (void)openPostActions {
    // Three Categories of Post Actions
    // 1) Any user
    // 2) Creator
    // 3) Admin
    BOOL isCreator     = ([self.post.attributes.details.creator.identifier isEqualToString:[Session sharedInstance].currentUser.identifier]);
    BOOL isRoomAdmin   = false;
    
    // Page action can be shown on
    // A) Any page
    // B) Inside Room
    // BOOL insideRoom    = true; // compare ID of post room and active room
    
    // Following state
    // *) Any Following State
    // +) Following Room
    // &) Following User
    // BOOL followingRoom = true;
    BOOL followingUser = true;
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    actionSheet.view.tintColor = [UIColor colorWithWhite:0.2 alpha:1];
    
    // 1.A.* -- Any user, any page, any following state
    BOOL hasiMessage = [MFMessageComposeViewController canSendText];
    if (hasiMessage) {
        UIAlertAction *shareOniMessage = [UIAlertAction actionWithTitle:@"Share on iMessage" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSString *message = @"Join my Room on Bonfire! https://bonfire.app/room/room-name";
            [[Launcher sharedInstance] shareOniMessage:message image:nil];
        }];
        [actionSheet addAction:shareOniMessage];
    }
    
    // 1.A.* -- Any user, any page, any following state
    UIAlertAction *sharePost = [UIAlertAction actionWithTitle:@"Share via..." style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"share post");
    }];
    [actionSheet addAction:sharePost];
    
    // 2.A.* -- Creator, any page, any following state
    // TODO: Hook this up to a JSON default
    
    // Turn off Quick Fix for now and introduce later
    /*
     if (isCreator) {
     UIAlertAction *editPost = [UIAlertAction actionWithTitle:@"Quick Fix" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
     NSLog(@"quick fix");
     // confirm action
     }];
     [actionSheet addAction:editPost];
     }*/
    
    // !2.A.* -- Not Creator, any page, any following state
    if (!isCreator) {
        UIAlertAction *reportPost = [UIAlertAction actionWithTitle:@"Report Post" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            // confirm action
            UIAlertController *confirmDeletePostActionSheet = [UIAlertController alertControllerWithTitle:@"Report Post" message:@"Are you sure you want to report this post?" preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *confirmDeletePost = [UIAlertAction actionWithTitle:@"Report" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                [[Session sharedInstance] reportPost:self.post.identifier completion:^(BOOL success, id responseObject) {
                    // NSLog(@"reported post!");
                }];
            }];
            [confirmDeletePostActionSheet addAction:confirmDeletePost];
            
            UIAlertAction *cancelDeletePost = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
            [confirmDeletePostActionSheet addAction:cancelDeletePost];
            
            [UIViewParentController(self) presentViewController:confirmDeletePostActionSheet animated:YES completion:nil];
        }];
        [actionSheet addAction:reportPost];
    }
    
    // !2.A.* -- Not Creator, any page, any following state
    if (!isCreator) {
        UIAlertAction *followUser = [UIAlertAction actionWithTitle:(followingUser?@"Follow @username":@"Unfollow @username") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            // TODO: Update the user's context
            if (followingUser) {
                [[Session sharedInstance] unfollowUser:self.post.attributes.details.creator completion:^(BOOL success, id responseObject) {
                    // NSLog(@"unfollowed user!");
                }];
            }
            else {
                [[Session sharedInstance] followUser:self.post.attributes.details.creator completion:^(BOOL success, id responseObject) {
                    // NSLog(@"followed user!");
                }];
            }
        }];
        [actionSheet addAction:followUser];
    }
    
    // 2|3.A.* -- Creator or room admin, any page, any following state
    if (isCreator || isRoomAdmin) {
        UIAlertAction *deletePost = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [actionSheet dismissViewControllerAnimated:YES completion:nil];
            // confirm action
            UIAlertController *confirmDeletePostActionSheet = [UIAlertController alertControllerWithTitle:@"Delete Post" message:@"Are you sure you want to delete this post?" preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *confirmDeletePost = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                NSLog(@"delete post");
                // confirm action
                [[Session sharedInstance] deletePost:self.post completion:^(BOOL success, id responseObject) {
                    if (success) {
                        // NSLog(@"deleted post!");
                    }
                }];
            }];
            [confirmDeletePostActionSheet addAction:confirmDeletePost];
            
            UIAlertAction *cancelDeletePost = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
            [confirmDeletePostActionSheet addAction:cancelDeletePost];
            
            [UIViewParentController(self) presentViewController:confirmDeletePostActionSheet animated:YES completion:nil];
        }];
        [actionSheet addAction:deletePost];
    }
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [cancel setValue:self.tintColor forKey:@"titleTextColor"];
    [actionSheet addAction:cancel];
    
    [UIViewParentController(self).navigationController presentViewController:actionSheet animated:YES completion:nil];
}

- (void)showSharePostSheet {
    UIActivityViewController *controller = [[UIActivityViewController alloc]initWithActivityItems:@[@"hi insta"] applicationActivities:nil];
    
    // and present it
    controller.modalPresentationStyle = UIModalPresentationPopover;
    [UIViewParentController(self) presentViewController:controller animated:YES completion:nil];
}

// Setter method
- (void)setSparked:(BOOL)isSparked withAnimation:(BOOL)animated {
    if (!animated || (animated && isSparked != self.sparked)) {
        self.sparked = isSparked;
        
        [UIView animateWithDuration:animated?0.5f:0 delay:animated?0.3f:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.sparkedIcon.alpha = isSparked ? 1 : 0;
            self.sparkedIcon.frame = CGRectMake(self.bounds.size.width - (isSparked ? postContentOffset.right + self.sparkedIcon.frame.size.width : 0), self.sparkedIcon.frame.origin.y, self.sparkedIcon.frame.size.width, self.sparkedIcon.frame.size.height);
        } completion:nil];
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    if (self.selectable) {
        if (highlighted && panRecognizer.state == UIGestureRecognizerStatePossible) {
            self.layer.masksToBounds = true;
            panRecognizer.enabled = false;
            [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                // self.transform = CGAffineTransformMakeScale(0.9, 0.9);
                self.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1];
            } completion:nil];
        }
        else if (!highlighted && panRecognizer.enabled == false) {
            self.layer.masksToBounds = false;
            panRecognizer.enabled = true;
            [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                // self.transform = CGAffineTransformMakeScale(1, 1);
                self.backgroundColor = [UIColor clearColor];
            } completion:nil];
        }
    }
}

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

@end
