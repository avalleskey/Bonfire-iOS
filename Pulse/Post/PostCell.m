//
//  PostCell.m
//  Pulse
//
//  Created by Austin Valleskey on 3/10/18.
//  Copyright © 2018 Ingenious, Inc. All rights reserved.
//

#import "PostCell.h"
#import <BlocksKit/BlocksKit+UIKit.h>
#import <SafariServices/SafariServices.h>
#import <HapticHelper/HapticHelper.h>
#import "Session.h"

#define UIViewParentController(__view) ({ \
    UIResponder *__responder = __view; \
    while ([__responder isKindOfClass:[UIView class]]) \
    __responder = [__responder nextResponder]; \
    (UIViewController *)__responder; \
    })

@implementation PostCell {
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
        self.backgroundColor = [UIColor whiteColor];
        
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenRect.size.width;
        
        self.contentView.frame = CGRectMake(0, 0, screenWidth, 100);
        self.contentView.backgroundColor = [UIColor clearColor];
        self.contentView.layer.masksToBounds = true;
        
        self.post = [[Post alloc] init];
        
        self.leftBar = [[UIView alloc] initWithFrame:CGRectMake(-3, 6, 6, self.frame.size.height - 12)];
        self.leftBar.hidden = true;
        self.leftBar.layer.cornerRadius = 4.f;
        [self.contentView addSubview:self.leftBar];
        
        self.profilePicture = [[UIImageView alloc] initWithFrame:CGRectMake(12, 10, 40, 40)];
        [self continuityRadiusForView:self.profilePicture withRadius:10.f];
        [self.profilePicture setImage:[[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        self.profilePicture.layer.masksToBounds = true;
        self.profilePicture.backgroundColor = [UIColor whiteColor];
        self.profilePicture.userInteractionEnabled = true;
        [self.contentView addSubview:self.profilePicture];
        
        self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(_postContentOffset.left, _postContentOffset.top, self.contentView.frame.size.width - _postContentOffset.left - 50, 16)];
        self.nameLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightBold];
        self.nameLabel.textAlignment = NSTextAlignmentLeft;
        self.nameLabel.text = @"Display Name";
        self.nameLabel.textColor = [UIColor colorWithWhite:0.2f alpha:1];
        [self.contentView addSubview:self.nameLabel];
        
        self.dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width - _postContentOffset.right - 96, _postContentOffset.top, 96, self.nameLabel.frame.size.height)];
        self.dateLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightRegular];
        self.dateLabel.textAlignment = NSTextAlignmentRight;
        self.dateLabel.text = @"4h";
        self.dateLabel.textColor = [UIColor colorWithWhite:0.6f alpha:1];
        [self.contentView addSubview:self.dateLabel];
        
        self.sparked = false;
        self.sparkedIcon = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width, self.nameLabel.frame.origin.y, 20, self.nameLabel.frame.size.height)];
        self.sparkedIcon.contentMode = UIViewContentModeCenter;
        self.sparkedIcon.alpha = 0;
        if ([[Session sharedInstance].defaults.post.displayVote.icon isEqualToString:@"star"]) {
            [self.sparkedIcon setImage:[UIImage imageNamed:@"cellIndicatorStar"]];
        }
        else if ([[Session sharedInstance].defaults.post.displayVote.icon isEqualToString:@"heart"]) {
            [self.sparkedIcon setImage:[UIImage imageNamed:@"cellIndicatorHeart"]];
        }
        else if ([[Session sharedInstance].defaults.post.displayVote.icon isEqualToString:@"thumb"]) {
            [self.sparkedIcon setImage:[UIImage imageNamed:@"cellIndicatorThumb"]];
        }
        else if ([[Session sharedInstance].defaults.post.displayVote.icon isEqualToString:@"flame"]) {
            [self.sparkedIcon setImage:[UIImage imageNamed:@"cellIndicatorFlame"]];
        }
        else {
            [self.sparkedIcon setImage:[UIImage imageNamed:@"cellIndicatorBolt"]];
        }
        self.sparkedIcon.frame = CGRectMake(self.sparkedIcon.frame.origin.x, self.sparkedIcon.frame.origin.y, self.sparkedIcon.image.size.width, self.sparkedIcon.frame.size.height);
        [self.contentView addSubview:self.sparkedIcon];
        
        self.moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.moreButton setImage:[UIImage imageNamed:@"moreIcon"] forState:UIControlStateNormal];
        self.moreButton.frame = CGRectMake(self.frame.size.width - 42 + 12, _postContentOffset.top + (self.nameLabel.frame.size.height / 2) - 20, 42, 40); // result should be 8
        //[self.contentView addSubview:self.moreButton];
        
        // text view
        self.textView = [[PostTextView alloc] initWithFrame:CGRectMake(_postContentOffset.left, 58, self.contentView.frame.size.width - _postContentOffset.right - _postContentOffset.left, 200)]; // 58 will change based on whether or not the detail label is shown
        self.textView.textView.editable = false;
        self.textView.textView.selectable = false;
        self.textView.textView.userInteractionEnabled = false;
        self.textView.textView.font = _textViewFont;
        [self.contentView addSubview:self.textView];
        
        // image view
        self.pictureView = [[UIImageView alloc] initWithFrame:CGRectMake(self.textView.frame.origin.x, 56, self.textView.frame.size.width, postImageHeight)];
        self.pictureView.backgroundColor = [UIColor colorWithRed:0.91 green:0.92 blue:0.93 alpha:1.0];
        [self continuityRadiusForView:self.pictureView withRadius:12.f];
        self.pictureView.contentMode = UIViewContentModeScaleAspectFill;
        self.pictureView.layer.masksToBounds = true;
        self.pictureView.userInteractionEnabled = true;
        [self.contentView addSubview:self.pictureView];
        
        self.postDetailsButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.postDetailsButton.frame = CGRectMake(_postContentOffset.left, self.pictureView.frame.origin.y + self.pictureView.frame.size.height + 2, self.nameLabel.frame.size.width, 14);
        self.postDetailsButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [self.postDetailsButton setTitle:@"Room Name" forState:UIControlStateNormal];
        [self.postDetailsButton setTitleColor:[UIColor colorWithWhite:0.6f alpha:1] forState:UIControlStateNormal];
        self.postDetailsButton.titleLabel.font = [UIFont systemFontOfSize:12.f weight:UIFontWeightRegular];
        //[self.contentView addSubview:self.postDetailsButton];
        
        self.lineSeparator = [[UIView alloc] init];
        self.lineSeparator.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1];
        //[self.contentView addSubview:self.lineSeparator];
        
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
        
        
        CGRect dateLabelRect = [self.dateLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width / 2, self.dateLabel.frame.size.height) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.dateLabel.font} context:nil];
        self.dateLabel.frame = CGRectMake(self.frame.size.width - _postContentOffset.right - dateLabelRect.size.width, self.dateLabel.frame.origin.y, ceilf(dateLabelRect.size.width), self.dateLabel.frame.size.height);
        
        self.nameLabel.frame = CGRectMake(self.nameLabel.frame.origin.x, self.nameLabel.frame.origin.y, self.dateLabel.frame.origin.x - self.nameLabel.frame.origin.x - 8, self.nameLabel.frame.size.height);
        self.sparkedIcon.frame = CGRectMake(self.bounds.size.width - (self.sparked ? _postContentOffset.right + self.sparkedIcon.frame.size.width : 0), self.sparkedIcon.frame.origin.y, self.sparkedIcon.frame.size.width, self.sparkedIcon.frame.size.height);
        
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
        self.textView.frame = CGRectMake(self.textView.frame.origin.x, self.nameLabel.frame.origin.y + self.nameLabel.frame.size.height + 2, self.textView.frame.size.width, self.textView.frame.size.height);
        
        self.moreButton.frame = CGRectMake(self.frame.size.width - self.moreButton.frame.size.width, self.moreButton.frame.origin.y, self.moreButton.frame.size.width, self.moreButton.frame.size.height);
        
        BOOL hasImage = false; //self.post.images != nil && self.post.images.count > 0;
        if (hasImage) {
            self.pictureView.hidden = false;
            self.pictureView.frame = CGRectMake(self.pictureView.frame.origin.x, self.textView.frame.origin.y + self.textView.frame.size.height + 6, self.pictureView.frame.size.width, self.pictureView.frame.size.height);
            //[self.pictureView sd_setImageWithURL:[NSURL URLWithString:self.post.images[0]]];
            
            // -- details
            self.postDetailsButton.frame = CGRectMake(self.postDetailsButton.frame.origin.x, self.pictureView.frame.origin.y + self.pictureView.frame.size.height + 4, self.textView.frame.size.width, self.postDetailsButton.frame.size.height);
        }
        else {
            self.pictureView.hidden = true;
            
            // -- details
            self.postDetailsButton.frame = CGRectMake(self.postDetailsButton.frame.origin.x, self.textView.frame.origin.y + self.textView.frame.size.height + 4, self.textView.frame.size.width, self.postDetailsButton.frame.size.height);
        }
        
        self.sparkIndicator.frame = CGRectMake(self.sparkIndicator.frame.origin.x, self.frame.size.height / 2 - (self.sparkIndicator.frame.size.height / 2), self.sparkIndicator.frame.size.width, self.sparkIndicator.frame.size.height);
        self.replyIndicator.frame = CGRectMake(self.frame.size.width + 16, self.frame.size.height / 2 - (self.replyIndicator.frame.size.height / 2), self.replyIndicator.frame.size.width, self.replyIndicator.frame.size.height);
        self.replyIndicator.backgroundColor = self.tintColor;
        
        [self continuityRadiusForView:self.contentView withRadius:12.f];
    }
}

// Pan gesture recognizer for left and right swipes
- (void)initalizePan {
    panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    panRecognizer.delegate = self;
    [self addGestureRecognizer:panRecognizer];
    
    UIColor *defaultBackgroundColor = [UIColor colorWithWhite:0.96 alpha:1];
    
    self.sparkIndicator = [[UIImageView alloc] initWithFrame:CGRectMake(-44 - 16, (self.frame.size.height / 2) - 22, 44, 44)];
    self.sparkIndicator.layer.cornerRadius = self.sparkIndicator.frame.size.height / 2;
    self.sparkIndicator.layer.masksToBounds = true;
    self.sparkIndicator.tintColor = defaultBackgroundColor;
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
        self.sparkIndicator.backgroundColor = [UIColor colorWithDisplayP3Red:0.99 green:0.26 blue:0.12 alpha:1.0];
    }
    sparkColor = self.sparkIndicator.backgroundColor;
    [self addSubview:self.sparkIndicator];
    
    self.replyIndicator = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width + 16, (self.frame.size.height / 2) - 22, 44, 44)];
    self.replyIndicator.layer.cornerRadius = self.replyIndicator.frame.size.height / 2;
    self.replyIndicator.layer.masksToBounds = true;
    self.replyIndicator.tintColor = defaultBackgroundColor;
    self.replyIndicator.backgroundColor = self.tintColor;
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
        UIColor *color = sparkColor;
        
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            if (self.frame.origin.x > 0) {
                // left swipe
                self.contentView.backgroundColor = self.sparked ? [UIColor colorWithWhite:0 alpha:0.04f] : [color colorWithAlphaComponent:0.06f];
            }
            else {
                // right swipe
                self.contentView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.04f];
            }
        } completion:nil];
    }
    
    if (recognizer.state == UIGestureRecognizerStateChanged) {
        [self checkIfSwiped:recognizer];
    }
    
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        CGRect originalFrame = CGRectMake(0, recognizer.view.frame.origin.y, recognizer.view.bounds.size.width, recognizer.view.bounds.size.height);
        if (isLeftSwipeSuccessful) {
            NSLog(@"left swipe successful");
            NSLog(@"self sparked? %@", self.sparked ? @"YES" : @"NO");
            NSLog(@"self !sparked? %@", !self.sparked ? @"YES" : @"NO");
            [self setSparked:!self.sparked withAnimation:YES];

        }
        if (isRightSwipeSuccessful) {
            NSLog(@"right swipe successful");
            [self showSharePostSheet];
        }
        [self moveViewBackIntoPlace:originalFrame];
        
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.contentView.backgroundColor = [UIColor clearColor];
        } completion:nil];
    }
}
- (void)checkIfSwiped:(UIPanGestureRecognizer *)recognizer {
    CGPoint translation = [recognizer translationInView:self];
    CGPoint center = CGPointMake(originalCenter.x + translation.x, originalCenter.y);
    self.center = center;
    isLeftSwipeSuccessful = self.frame.origin.x > self.frame.size.width / 3;
    isRightSwipeSuccessful = self.frame.origin.x < (self.frame.size.width / 3) * -1;
    
    UIColor *defaultBackgroundColor = [UIColor colorWithWhite:0.96 alpha:1];
    
    UIColor *sparkDefaultTintColor = self.sparked ? sparkColor : defaultBackgroundColor;
    UIColor *sparkDefaultBackgroundColor = self.sparked ? [UIColor whiteColor] : sparkColor;
    
    UIColor *sparkSuccessTintColor = self.sparked ? defaultBackgroundColor : sparkColor;
    UIColor *sparkSuccessBackgroundColor = self.sparked ? sparkColor : [UIColor whiteColor];
    
    if (isLeftSwipeSuccessful && self.contentView.tag != 1) {
        self.contentView.tag = 1;
        UIColor *color = sparkColor;
        
        [HapticHelper generateFeedback:FeedbackType_Impact_Medium];
        [UIView animateWithDuration:0.15f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.contentView.backgroundColor = self.sparked ? [UIColor colorWithWhite:0 alpha:0.04f] : [color colorWithAlphaComponent:0.06f];
            
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
            self.contentView.backgroundColor = [self.tintColor colorWithAlphaComponent:0.06f];
            
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
            self.contentView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.04f];
            
            self.sparkIndicator.tintColor = sparkDefaultTintColor;
            self.sparkIndicator.backgroundColor = sparkDefaultBackgroundColor;
            
            self.replyIndicator.tintColor = defaultBackgroundColor;
            self.replyIndicator.backgroundColor = self.tintColor;
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
    [self showPostActions];
}
- (void)showPostActions {
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    // imessage , share via...
    
    UIAlertAction *shareOnImessage = [UIAlertAction actionWithTitle:@"Share on iMessage" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"share on imessage");
    }];
    [actionSheet addAction:shareOnImessage];
    
    UIAlertAction *shareVia = [UIAlertAction actionWithTitle:@"Share via..." style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"share via...");
        [self showSharePostSheet];
    }];
    [actionSheet addAction:shareVia];
    
    UIAlertAction *copyLink = [UIAlertAction actionWithTitle:@"Copy Link" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"copy link");
    }];
    [actionSheet addAction:copyLink];
    
    if ([self.post.attributes.details.creator.identifier isEqualToString:[Session sharedInstance].currentUser.identifier]) {
        UIAlertAction *deletePost = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"delete post");
        }];
        [actionSheet addAction:deletePost];
    }
    else {
        BOOL isPostNotificationsOn = false;
        UIAlertAction *postNotifications = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Turn %@ Post Notifications", isPostNotificationsOn ? @"Off" : @"On"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"copy link");
        }];
        [actionSheet addAction:postNotifications];
        
        UIAlertAction *reportPost = [UIAlertAction actionWithTitle:@"Report" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"report post");
        }];
        [actionSheet addAction:reportPost];
    }
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"cancel");
    }];
    [actionSheet addAction:cancel];
    
    [UIViewParentController(self) presentViewController:actionSheet animated:YES completion:nil];
}

- (void)showSharePostSheet {
    UIActivityViewController *controller = [[UIActivityViewController alloc]initWithActivityItems:@[@"hi insta"] applicationActivities:nil];
    
    // and present it
    controller.modalPresentationStyle = UIModalPresentationPopover;
    [UIViewParentController(self) presentViewController:controller animated:YES completion:nil];
}

//Setter method
- (void)setSparked:(BOOL)isSparked withAnimation:(BOOL)animated {
    if (isSparked != self.sparked) {
        self.sparked = isSparked;
//        NSLog(@"isSparked? %@", isSparked ? @"YES" : @"NO");
        NSLog(@"new x: %f", self.frame.size.width - (isSparked ? _postContentOffset.right + self.sparkedIcon.frame.size.width : 0));
        
        [UIView animateWithDuration:animated?0.5f:0 delay:animated?0.3f:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.dateLabel.alpha = isSparked ? 0 : 1;
            self.sparkedIcon.alpha = isSparked ? 1 : 0;
            self.sparkedIcon.frame = CGRectMake(self.bounds.size.width - (isSparked ? _postContentOffset.right + self.sparkedIcon.frame.size.width : 0), self.sparkedIcon.frame.origin.y, self.sparkedIcon.frame.size.width, self.sparkedIcon.frame.size.height);
        } completion:nil];
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
//    NSLog(@"highlighted? %@", highlighted ? @"YES" : @"NO");
//    NSLog(@"gesture state possible? %@", panRecognizer.state == UIGestureRecognizerStatePossible ? @"YES" : @"NO");
    
    if (self.selectable) {
        if (highlighted && panRecognizer.state == UIGestureRecognizerStatePossible) {
            self.layer.masksToBounds = true;
            panRecognizer.enabled = false;
            [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.transform = CGAffineTransformMakeScale(0.9, 0.9);
                self.contentView.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1];
            } completion:nil];
        }
        else if (!highlighted && panRecognizer.enabled == false) {
            self.layer.masksToBounds = false;
            panRecognizer.enabled = true;
            [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.transform = CGAffineTransformMakeScale(1, 1);
                self.contentView.backgroundColor = [UIColor clearColor];
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

- (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    if (hexString != nil && hexString.length == 6) {
        NSScanner *scanner = [NSScanner scannerWithString:hexString];
        [scanner setScanLocation:0]; // bypass '#' character
        [scanner scanHexInt:&rgbValue];
        return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
    }
    else {
        return [UIColor colorWithWhite:0.2f alpha:1];
    }
}

@end
