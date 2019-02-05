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

@implementation BubblePostCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.selectable = true;
        self.threaded = false;
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor whiteColor];
        self.layer.masksToBounds = true;
        
        self.contentView.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 100);
        self.contentView.backgroundColor = [UIColor whiteColor];
        self.contentView.layer.shadowRadius = 1.f;
        self.contentView.layer.shadowColor = [UIColor blackColor].CGColor;
        self.contentView.layer.shadowOpacity = 0;
        self.contentView.layer.shadowOffset = CGSizeMake(0, 0);
        self.contentView.layer.masksToBounds = true;
        
        self.post = [[Post alloc] init];
        
        self.contextView = [[PostContextView alloc] init];
        [self.contentView addSubview:self.contextView];
        
        self.profilePicture = [[BFAvatarView alloc] initWithFrame:CGRectMake(12, postContentOffset.top + 2, 48, 48)];
        self.profilePicture.openOnTap = false;
        self.profilePicture.dimsViewOnTap = true;
        self.profilePicture.allowOnlineDot = true;
        [self.profilePicture bk_whenTapped:^{
            [[Launcher sharedInstance] openProfile:self.post.attributes.details.creator];
        }];
        [self.contentView addSubview:self.profilePicture];
        
        self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(postContentOffset.left + 4, postContentOffset.top, self.contentView.frame.size.width - (postContentOffset.left + 4) - postContentOffset.right, 16)];
        self.nameLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightSemibold];
        self.nameLabel.textAlignment = NSTextAlignmentLeft;
        self.nameLabel.text = @"Display Name";
        self.nameLabel.textColor = [UIColor colorWithWhite:0.27f alpha:1];
        self.nameLabel.numberOfLines = 1;
        self.nameLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        self.nameLabel.userInteractionEnabled = YES;
        [self.contentView addSubview:self.nameLabel];
        
        // (!isReply && postedInRoom != nil && ![postedInRoom.identifier isEqualToString:currentRoomIdentifier]) ? 18 : 0;
        self.postedInButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.postedInButton.frame = CGRectMake(self.nameLabel.frame.origin.x, self.nameLabel.frame.origin.y + self.nameLabel.frame.size.height + 4, self.nameLabel.frame.size.width, 14);
        self.postedInButton.titleLabel.font = [UIFont systemFontOfSize:12.f weight:UIFontWeightSemibold];
        self.postedInButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [self.postedInButton setTitle:@"Camp Name" forState:UIControlStateNormal];
        [self.postedInButton setTitleColor:[UIColor bonfireOrange] forState:UIControlStateNormal];
        [self.postedInButton setImage:[[UIImage imageNamed:@"replyingToIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [self.postedInButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 4, 0, 0)];
        [self.contentView addSubview:self.postedInButton];
        
        self.sparked = false;
        
        // text view
        self.textView = [[PostTextView alloc] initWithFrame:CGRectMake(postContentOffset.left, 58, self.contentView.frame.size.width - (postContentOffset.left + postContentOffset.right), 200)]; // 58 will change based on whether or not the detail label is shown
        self.textView.messageLabel.font = textViewFont;
        self.textView.delegate = self;
        [self setThemed:false];
        [self.contentView addSubview:self.textView];
        
        self.lineSeparator = [[UIView alloc] init];
        self.lineSeparator.backgroundColor = [UIColor separatorColor];
        [self addSubview:self.lineSeparator];
        
        self.repliesSnapshotView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 20)];
        UIView *threadLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 3, self.repliesSnapshotView.frame.size.height)];
        threadLine.backgroundColor = [UIColor colorWithRed:0.92 green:0.93 blue:0.93 alpha:1.00];
        threadLine.layer.cornerRadius = threadLine.frame.size.width / 2;
        threadLine.layer.masksToBounds = true;
        [self.repliesSnapshotView addSubview:threadLine];
        self.repliesSnapshotAvatar = [[BFAvatarView alloc] initWithFrame:CGRectMake(8, 0, self.repliesSnapshotView.frame.size.height, self.repliesSnapshotView.frame.size.height)];
        [self.repliesSnapshotView addSubview:self.repliesSnapshotAvatar];
        self.repliesSnapshotLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.repliesSnapshotAvatar.frame.origin.x + self.repliesSnapshotAvatar.frame.size.width + 8, 0, self.repliesSnapshotView.frame.size.width - (self.repliesSnapshotAvatar.frame.origin.x + self.repliesSnapshotAvatar.frame.size.width + 8), self.repliesSnapshotView.frame.size.height)];
        self.repliesSnapshotLabel.font = [UIFont systemFontOfSize:12.f weight:UIFontWeightRegular];
        self.repliesSnapshotLabel.textColor = [UIColor colorWithWhite:0.27 alpha:1];
        self.repliesSnapshotLabel.textAlignment = NSTextAlignmentLeft;
        [self.repliesSnapshotView addSubview:self.repliesSnapshotLabel];
        [self addSubview:self.repliesSnapshotView];
        
        self.detailsView = [[UIView alloc] initWithFrame:CGRectMake(self.nameLabel.frame.origin.x + postTextViewInset.left, 0, self.nameLabel.frame.size.width - (postTextViewInset.left + postTextViewInset.right), 16)];
        [self.contentView addSubview:self.detailsView];
        
        self.detailDateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 21, self.detailsView.frame.size.height)];
        self.detailDateLabel.font = [UIFont systemFontOfSize:13.f weight:UIFontWeightRegular];
        self.detailDateLabel.textColor = [UIColor colorWithWhite:0.47 alpha:1];
        [self.detailsView addSubview:self.detailDateLabel];
        
        self.detailSparkButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.detailSparkButton setTitle:[Session sharedInstance].defaults.post.displayVote.text forState:UIControlStateNormal];
        self.detailSparkButton.titleLabel.font = [UIFont systemFontOfSize:self.detailDateLabel.font.pointSize weight:UIFontWeightSemibold];
        [self.detailSparkButton setTitleColor:[UIColor colorWithWhite:0.47 alpha:1] forState:UIControlStateNormal];
        CGSize sparkButtonSize = [self.detailSparkButton.currentTitle boundingRectWithSize:CGSizeMake(100, self.detailsView.frame.size.height) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName: self.detailSparkButton.titleLabel.font} context:nil].size;
        self.detailSparkButton.frame = CGRectMake(self.detailDateLabel.frame.origin.x + self.detailDateLabel.frame.size.width + 14, 0, ceilf(sparkButtonSize.width) + 2, self.detailsView.frame.size.height);
        
        [self.detailSparkButton bk_whenTapped:^{
            [self setSparked:!self.sparked withAnimation:SparkAnimationTypeAll];
            
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
        }];
        
        [self.detailsView addSubview:self.detailSparkButton];
        
        self.detailReplyButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.detailReplyButton setTitle:@"Reply" forState:UIControlStateNormal];
        self.detailReplyButton.titleLabel.font = [UIFont systemFontOfSize:self.detailDateLabel.font.pointSize weight:UIFontWeightSemibold];
        [self.detailReplyButton setTitleColor:[UIColor colorWithWhite:0.47 alpha:1] forState:UIControlStateNormal];
        self.detailReplyButton.frame = CGRectMake(self.detailSparkButton.frame.origin.x + self.detailSparkButton.frame.size.width + 13, 0, 36, self.detailsView.frame.size.height);
        
        [self.detailReplyButton bk_whenTapped:^{
            [[Launcher sharedInstance] openPost:self.post withKeyboard:YES];
        }];
        
        [self.detailsView addSubview:self.detailReplyButton];
    }
    
    return self;
}

- (void)initPictureView {
    // image view
    self.pictureView = [[UIImageView alloc] initWithFrame:CGRectMake(self.textView.frame.origin.x, 56, self.textView.frame.size.width, [Session sharedInstance].defaults.post.imgHeight)];
    self.pictureView.backgroundColor = [UIColor colorWithRed:0.92 green:0.93 blue:0.94 alpha:1.0];
    self.pictureView.layer.cornerRadius = 17.f;
    self.pictureView.layer.masksToBounds = true;
    self.pictureView.contentMode = UIViewContentModeScaleAspectFill;
    self.pictureView.layer.masksToBounds = true;
    self.pictureView.userInteractionEnabled = true;
    [self.pictureView bk_whenTapped:^{
        [[Launcher sharedInstance] expandImageView:self.pictureView];
    }];
    [self.contentView addSubview:self.pictureView];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat leftOffset = self.threaded ? replyContentOffset.left : postContentOffset.left;
    
    CGFloat yBottom = postContentOffset.top;
    
    self.lineSeparator.frame = CGRectMake(0, self.frame.size.height - (1 / [UIScreen mainScreen].scale), self.frame.size.width, 1 / [UIScreen mainScreen].scale);
    
    BOOL hasContext = false;
    self.contextView.hidden = !hasContext;
    if (hasContext) {
        self.contextView.frame = CGRectMake(self.profilePicture.frame.origin.x, postContentOffset.top, self.frame.size.width - (self.profilePicture.frame.origin.x + postContentOffset.right), postContextHeight);
        yBottom = self.contextView.frame.origin.y + self.contextView.frame.size.height + 8;
    }
    
    self.profilePicture.frame = CGRectMake((self.threaded ? postContentOffset.left : 12), yBottom, self.profilePicture.frame.size.width, self.profilePicture.frame.size.height);
    
    self.nameLabel.frame = CGRectMake(leftOffset + 4, yBottom, self.contentView.frame.size.width - (leftOffset + 4) - postContentOffset.right, self.nameLabel.frame.size.height);
    yBottom = self.nameLabel.frame.origin.y + self.nameLabel.frame.size.height;
    
    if (!self.postedInButton.hidden) {
        self.postedInButton.frame = CGRectMake(self.nameLabel.frame.origin.x, self.nameLabel.frame.origin.y + self.nameLabel.frame.size.height + 4, self.postedInButton.intrinsicContentSize.width + self.postedInButton.titleEdgeInsets.left, self.postedInButton.frame.size.height);
        yBottom = self.postedInButton.frame.origin.y + self.postedInButton.frame.size.height + 2; // extra 2pt padding undeanth compared to just showing the display name
    }
    
    // -- text view
    self.textView.tintColor = self.tintColor;
    [self.textView resize];
    self.textView.frame = CGRectMake(leftOffset, yBottom + 4, self.textView.frame.size.width, self.textView.frame.size.height);
    yBottom = self.textView.frame.origin.y + self.textView.frame.size.height;
        
    BOOL hasImage = FBTweakValue(@"Post", @"General", @"Show Image", NO); //self.post.images != nil && self.post.images.count > 0;
    if (hasImage) {
        if (!self.pictureView) {
            [self initPictureView];
        }
        
        self.pictureView.frame = CGRectMake(self.textView.frame.origin.x, yBottom + (self.post.attributes.details.message.length != 0 ? 4 : 0), self.pictureView.frame.size.width, self.pictureView.frame.size.height);
        
        yBottom = self.pictureView.frame.origin.y + self.pictureView.frame.size.height;
    }
    else {
        if (self.pictureView) {
            self.pictureView = nil;
            [self.pictureView removeFromSuperview];
        }
        
        yBottom = self.textView.frame.origin.y + self.textView.frame.size.height;
    }
    
    if (!self.repliesSnapshotView.isHidden) {
        self.repliesSnapshotView.frame = CGRectMake(self.nameLabel.frame.origin.x, yBottom + 6, self.frame.size.width - self.nameLabel.frame.origin.x - postContentOffset.right, self.repliesSnapshotView.frame.size.height);
        self.repliesSnapshotLabel.frame = CGRectMake(self.repliesSnapshotLabel.frame.origin.x, 0, self.repliesSnapshotView.frame.size.width - self.repliesSnapshotLabel.frame.origin.x, self.repliesSnapshotView.frame.size.height);
        yBottom = self.repliesSnapshotView.frame.origin.y + self.repliesSnapshotView.frame.size.height + 4;
    }
    
    CGSize dateLabelSize = [self.detailDateLabel.text boundingRectWithSize:CGSizeMake(100, self.detailsView.frame.size.height) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName: self.detailDateLabel.font} context:nil].size;
    self.detailDateLabel.frame = CGRectMake(self.detailDateLabel.frame.origin.x, self.detailDateLabel.frame.origin.y, ceilf(dateLabelSize.width), self.detailDateLabel.frame.size.height);
    CGFloat detailSpacing = 14;
    self.detailSparkButton.frame = CGRectMake(self.detailDateLabel.frame.origin.x + self.detailDateLabel.frame.size.width + detailSpacing, self.detailSparkButton.frame.origin.y, self.detailSparkButton.frame.size.width, self.detailSparkButton.frame.size.height);
    
    CGSize replyLabelSize = [self.detailReplyButton.currentTitle boundingRectWithSize:CGSizeMake(140, self.detailsView.frame.size.height) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName: self.detailReplyButton.titleLabel.font} context:nil].size;
    self.detailReplyButton.frame = CGRectMake(self.detailSparkButton.frame.origin.x + self.detailSparkButton.frame.size.width + detailSpacing, self.detailReplyButton.frame.origin.y, ceilf(replyLabelSize.width), self.detailReplyButton.frame.size.height);
    
    self.detailsView.frame = CGRectMake(self.nameLabel.frame.origin.x, yBottom + 4, self.nameLabel.frame.size.width, self.detailsView.frame.size.height);
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
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    actionSheet.view.tintColor = [UIColor colorWithWhite:0.2 alpha:1];
    
    // 1.A.* -- Any user, any page, any following state
    BOOL hasiMessage = [MFMessageComposeViewController canSendText];
    if (hasiMessage) {
        UIAlertAction *shareOniMessage = [UIAlertAction actionWithTitle:@"Share on iMessage" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSString *url;
            if (self.post.attributes.status.postedIn != nil) {
                // posted in a room
                url = [NSString stringWithFormat:@"https://bonfire.com/rooms/%@/posts/%ld", self.post.attributes.status.postedIn.identifier, (long)self.post.identifier];
            }
            else {
                // posted on a profile
                url = [NSString stringWithFormat:@"https://bonfire.com/users/%@/posts/%ld", self.post.attributes.details.creator.identifier, (long)self.post.identifier];
            }
            
            NSString *message = [NSString stringWithFormat:@"%@  %@", self.post.attributes.details.message, url];
            [[Launcher sharedInstance] shareOniMessage:message image:nil];
        }];
        [actionSheet addAction:shareOniMessage];
    }
    
    // 1.A.* -- Any user, any page, any following state
    UIAlertAction *sharePost = [UIAlertAction actionWithTitle:@"Share via..." style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"share post");
        
        NSString *url;
        if (self.post.attributes.status.postedIn != nil) {
            // posted in a room
            url = [NSString stringWithFormat:@"https://bonfire.com/rooms/%@/posts/%ld", self.post.attributes.status.postedIn.identifier, (long)self.post.identifier];
        }
        else {
            // posted on a profile
            url = [NSString stringWithFormat:@"https://bonfire.com/users/%@/posts/%ld", self.post.attributes.details.creator.identifier, (long)self.post.identifier];
        }
        
        NSString *message = [NSString stringWithFormat:@"%@  %@", self.post.attributes.details.message, url];
        [[Launcher sharedInstance] shareOniMessage:message image:nil];
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
    
    [[Launcher.sharedInstance activeViewController] presentViewController:actionSheet animated:YES completion:nil];
}

// Setter method
- (void)postTextViewDidDoubleTap:(PostTextView *)postTextView {
    if (postTextView != self.textView)
        return;
    
    [self setSparked:!self.sparked withAnimation:SparkAnimationTypeAll];
}
- (void)setSparked:(BOOL)isSparked withAnimation:(SparkAnimationType)animationType {
    if (animationType == SparkAnimationTypeNone || (animationType != SparkAnimationTypeNone && isSparked != self.sparked)) {
        self.sparked = isSparked;
        
        if (animationType != SparkAnimationTypeNone && self.sparked)
            [HapticHelper generateFeedback:FeedbackType_Notification_Success];
        
        UIColor *sparkedColor;
        if (self.sparked) {
            if ([[Session sharedInstance].defaults.post.displayVote.icon isEqualToString:@"star"]) {
                sparkedColor = [UIColor colorWithDisplayP3Red:0.99 green:0.58 blue:0.12 alpha:1.0];
            }
            else if ([[Session sharedInstance].defaults.post.displayVote.icon isEqualToString:@"heart"]) {
                sparkedColor = [UIColor colorWithDisplayP3Red:0.89 green:0.10 blue:0.13 alpha:1.0];
            }
            else if ([[Session sharedInstance].defaults.post.displayVote.icon isEqualToString:@"thumb"]) {
                sparkedColor = [UIColor colorWithDisplayP3Red:0.00 green:0.46 blue:1.00 alpha:1.0];
            }
            else if ([[Session sharedInstance].defaults.post.displayVote.icon isEqualToString:@"flame"]) {
                sparkedColor = [UIColor colorWithDisplayP3Red:0.99 green:0.42 blue:0.12 alpha:1.0];
            }
            else {
                sparkedColor = [UIColor colorWithDisplayP3Red:0.99 green:0.26 blue:0.12 alpha:1.0];
            }
            
            [self.detailSparkButton setTitleColor:sparkedColor forState:UIControlStateNormal];
            self.detailSparkButton.titleLabel.font = [UIFont systemFontOfSize:self.detailDateLabel.font.pointSize weight:UIFontWeightBold];
        }
        else {
            [self.detailSparkButton setTitleColor:[UIColor colorWithWhite:0.47 alpha:1] forState:UIControlStateNormal];
            self.detailSparkButton.titleLabel.font = [UIFont systemFontOfSize:self.detailDateLabel.font.pointSize weight:UIFontWeightSemibold];
        }
        
        void(^buttonPopAnimation)(void) = ^() {
            if (!self.sparked)
                return;
            
            [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.detailSparkButton.transform = CGAffineTransformMakeScale(1.15, 1.15);
            } completion:^(BOOL finished) {
                // self.actionsView.sparkButton.transform = CGAffineTransformMakeScale(1, 1);
                [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.4f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                    self.detailSparkButton.transform = CGAffineTransformMakeScale(1, 1);
                } completion:nil];
            }];
        };
        
        void(^rippleAnimation)(void) = ^() {
            if (!self.sparked)
                return;
            
            if (self.post.attributes.details.message.length == 0)
                return;
            
            CGFloat bubbleDiamater = self.frame.size.width * 1.6;
            UIView *bubble = [[UIView alloc] initWithFrame:CGRectMake(0, 0, bubbleDiamater, bubbleDiamater)];
            bubble.center = self.textView.center;
            bubble.backgroundColor = [sparkedColor colorWithAlphaComponent:0.06];
            bubble.layer.cornerRadius = bubble.frame.size.height / 2;
            bubble.layer.masksToBounds = true;
            bubble.transform = CGAffineTransformMakeScale(0.01, 0.01);
            
            [self.contentView bringSubviewToFront:self.textView];
            [self.contentView insertSubview:bubble belowSubview:self.textView];
            
            [UIView animateWithDuration:1.f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                bubble.transform = CGAffineTransformIdentity;
            } completion:nil];
            [UIView animateWithDuration:1.f delay:0.1f options:UIViewAnimationOptionCurveEaseOut animations:^{
                bubble.alpha = 0;
            } completion:nil];
        };
        
        if (animationType == SparkAnimationTypeAll) {
            buttonPopAnimation();
            rippleAnimation();
        }
        if (animationType == SparkAnimationTypeButton) {
            buttonPopAnimation();
        }
        if (animationType == SparkAnimationTypeRipple) {
            rippleAnimation();
        }
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    if (self.selectable) {
        if (highlighted) {
            // panRecognizer.enabled = false;
            [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                // self.transform = CGAffineTransformMakeScale(0.9, 0.9);
                self.contentView.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1];
            } completion:nil];
        }
        else {
            // panRecognizer.enabled = true;
            [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                // self.transform = CGAffineTransformMakeScale(1, 1);
                self.contentView.backgroundColor = [UIColor whiteColor];
            } completion:nil];
        }
    }
}

- (void)setPost:(Post *)post {
    if (post != _post) {
        _post = post;
        // BOOL isCreator = [cell.post.attributes.details.creator.identifier isEqualToString:[Session sharedInstance].currentUser.identifier];
        
        self.nameLabel.attributedText = [BubblePostCell attributedCreatorStringForPost:_post];
        
        self.detailReplyButton.hidden =
        self.detailSparkButton.hidden = self.post.tempId;
        if (self.post.tempId) {
            self.detailDateLabel.text = @"Posting...";
            
            self.userInteractionEnabled = false;
        }
        else {
            NSString *timeAgo = [NSDate mysqlDatetimeFormattedAsTimeAgo:self.post.attributes.status.createdAt withForm:TimeAgoShortForm];
            self.detailDateLabel.text = timeAgo;
            
            self.userInteractionEnabled = true;
        }
        
        self.textView.message = self.post.attributes.details.simpleMessage;
        
        if (self.profilePicture.user != self.post.attributes.details.creator) {
            self.profilePicture.user = self.post.attributes.details.creator;
        }
        else {
            NSLog(@"no need to load new user");
        }
        
        self.profilePicture.online = false;
        
        NSInteger replies = (long)self.post.attributes.summaries.counts.replies;
        if (replies > 0) {
            UIFont *boldFont = [UIFont systemFontOfSize:12.f weight:UIFontWeightBold];
            UIFont *regularFont = [UIFont systemFontOfSize:boldFont.pointSize];
            
            if (self.post.attributes.summaries.replies.count > 0) {
                // has an avatar / name to use
                User *userToHighlight = [self.post.attributes.summaries.replies firstObject].attributes.details.creator;
                self.repliesSnapshotAvatar.user = userToHighlight;
                
                NSString *contextString = [NSString stringWithFormat:@"%@", userToHighlight.attributes.details.displayName];
                NSString *replyCountString = @" Replied";
                
                if (replies == 1) {
                    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
                    NSDate *postedDate = [formatter dateFromString:self.post.attributes.status.createdAt];
                    CGFloat hoursAgo = [postedDate timeIntervalSinceNow] / (60 * 60) * -1;
                    BOOL recently = hoursAgo < (3 * 24);
                    
                    replyCountString = [NSString stringWithFormat:@"%@ %@", replyCountString, (recently?@"Recently":@"")];
                }
                else {
                    replyCountString = [NSString stringWithFormat:@" Replied  ·  %ld Replies", replies];
                }
                
                NSMutableAttributedString *context = [[NSMutableAttributedString alloc] initWithString:contextString];
                [context addAttribute:NSForegroundColorAttributeName value:self.repliesSnapshotLabel.textColor range:NSMakeRange(0, contextString.length)];
                [context addAttribute:NSFontAttributeName value:boldFont range:NSMakeRange(0, contextString.length)];
                NSMutableAttributedString *replyCount = [[NSMutableAttributedString alloc] initWithString:replyCountString];
                [replyCount addAttribute:NSFontAttributeName value:regularFont range:NSMakeRange(0, replyCountString.length)];
                [replyCount addAttribute:NSForegroundColorAttributeName value:[self.repliesSnapshotLabel.textColor colorWithAlphaComponent:0.75] range:NSMakeRange(0, replyCountString.length)];
                [context appendAttributedString:replyCount];
                self.repliesSnapshotLabel.attributedText = context;
            }
            else {
                self.repliesSnapshotLabel.font = boldFont;
                NSString *repliesString = [NSString stringWithFormat:@"%ld %@", replies, (replies == 1 ? @"Reply" : @"Replies")];
                self.repliesSnapshotLabel.text = repliesString;
            }
        }

        [self setSparked:(self.post.attributes.context.vote != nil) withAnimation:SparkAnimationTypeNone];
    }
}

- (BOOL)isReply {
    return (self.post.attributes.details.parent != 0);
}

- (void)setThemed:(BOOL)themed {
    if (themed != _themed) {
        _themed = themed;
        
        if (_themed) {
            self.textView.backgroundView.backgroundColor =
            self.textView.bubbleTip.tintColor = self.tintColor;
            
            self.textView.messageLabel.textColor = [UIColor whiteColor];
            self.textView.tintColor = [UIColor colorWithWhite:1 alpha:0.95];
        }
        else {
            self.textView.backgroundView.backgroundColor =
            self.textView.bubbleTip.tintColor = kDefaultBubbleBackgroundColor;
            
            self.textView.messageLabel.textColor = [UIColor blackColor];
            self.textView.tintColor = self.tintColor;
        }
    }
}

+ (NSAttributedString *)attributedCreatorStringForPost:(Post *)post {
    // set display name + room name combo
    NSString *displayName = post.attributes.details.creator.attributes.details.displayName != nil ? post.attributes.details.creator.attributes.details.displayName : @"Anonymous";
    
    UIFont *font = [UIFont systemFontOfSize:14.f weight:UIFontWeightSemibold];
    UIColor *color = [UIColor colorWithWhite:0.27f alpha:1];
    
    NSMutableAttributedString *creatorString = [[NSMutableAttributedString alloc] initWithString:displayName];
    PatternTapResponder creatorTapResponder = ^(NSString *string) {
        [[Launcher sharedInstance] openProfile:post.attributes.details.creator];
    };
    [creatorString addAttribute:RLTapResponderAttributeName value:creatorTapResponder range:NSMakeRange(0, creatorString.length)];
    [creatorString addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, creatorString.length)];
    [creatorString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, creatorString.length)];
    [creatorString addAttribute:RLHighlightedForegroundColorAttributeName value:[UIColor colorWithWhite:0.2f alpha:0.5f] range:NSMakeRange(0, creatorString.length)];
    
    if (post.attributes.details.creator.attributes.details.identifier != nil) {
        NSMutableAttributedString *spacer = [[NSMutableAttributedString alloc] initWithString:@" "];
        [spacer addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, spacer.length)];
        [spacer addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, spacer.length)];
        [creatorString appendAttributedString:spacer];
        
        NSString *username = [NSString stringWithFormat:@"@%@", post.attributes.details.creator.attributes.details.identifier];
        NSMutableAttributedString *usernameString = [[NSMutableAttributedString alloc] initWithString:username];
        [usernameString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithWhite:0.6f alpha:1] range:NSMakeRange(0, usernameString.length)];
        [usernameString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:font.pointSize-1.f weight:UIFontWeightRegular] range:NSMakeRange(0, usernameString.length)];
        
        [creatorString appendAttributedString:usernameString];
    }
    
    BOOL isVerified = false;
    if (isVerified) {
        NSMutableAttributedString *spacer = [[NSMutableAttributedString alloc] initWithString:@" "];
        [spacer addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, spacer.length)];
        [spacer addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, spacer.length)];
        [creatorString appendAttributedString:spacer];
        
        // verified icon ☑️
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        attachment.image = [UIImage imageNamed:@"verifiedIcon_small"];
        [attachment setBounds:CGRectMake(0, roundf(font.capHeight - attachment.image.size.height)/2.f, attachment.image.size.width, attachment.image.size.height)];
        
        NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
        [creatorString appendAttributedString:attachmentString];
    }
    
    return creatorString;
}

@end
