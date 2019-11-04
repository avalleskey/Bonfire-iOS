//
//  PostCell.m
//  Pulse
//
//  Created by Austin Valleskey on 3/10/18.
//  Copyright © 2018 Ingenious, Inc. All rights reserved.
//

#import "StreamPostCell.h"
#import <BlocksKit/BlocksKit+UIKit.h>
#import <SafariServices/SafariServices.h>
#import <HapticHelper/HapticHelper.h>
#import "Session.h"
#import "ComplexNavigationController.h"
#import "Launcher.h"
#import "UIColor+Palette.h"

#define BFPostContextTextKey @"text"
#define BFPostContextIconKey @"icon"
#define BFPostContextIconColorKey @"icon_color"

#define STREAM_POST_MAX_CHARACTERS 300

@implementation StreamPostCell

@synthesize post = _post;

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.selectable = true;
        
        self.contextView = [[PostContextView alloc] init];
        [self.contentView addSubview:self.contextView];
        
        self.primaryAvatarView.openOnTap = false;
        self.primaryAvatarView.dimsViewOnTap = true;
        
        self.nameLabel.frame = CGRectMake(postContentOffset.left, postContentOffset.top, self.contentView.frame.size.width - postContentOffset.left - postContentOffset.right, 18);
        self.nameLabel.font = [UIFont systemFontOfSize:15.f weight:UIFontWeightSemibold];
        self.nameLabel.text = @"Display Name";
        self.nameLabel.userInteractionEnabled = YES;
        
        self.dateLabel.frame = CGRectMake(0, self.nameLabel.frame.origin.y, self.nameLabel.frame.origin.y, self.nameLabel.frame.size.height);
        self.dateLabel.font = [UIFont systemFontOfSize:self.nameLabel.font.pointSize weight:UIFontWeightRegular];
        self.dateLabel.textAlignment = NSTextAlignmentRight;
        
        self.voted = false;
        
        // text view
        self.textView.frame = CGRectMake(postContentOffset.left, 58, [UIScreen mainScreen].bounds.size.width - (postContentOffset.left + postContentOffset.right), 10000);
        self.textView.messageLabel.font = textViewFont;
        self.textView.delegate = self;
        self.textView.maxCharacters = STREAM_POST_MAX_CHARACTERS;
        self.textView.postId = self.post.identifier;
        
        // image view
        self.imagesView.frame = CGRectMake(self.textView.frame.origin.x, 56, self.textView.frame.size.width, [PostImagesView streamImageHeight]);
        
        self.actionsView = [[PostActionsView alloc] initWithFrame:CGRectMake(self.nameLabel.frame.origin.x + postTextViewInset.left, 0, self.nameLabel.frame.size.width - (postTextViewInset.left + postTextViewInset.right), POST_ACTIONS_VIEW_HEIGHT)];
        [self.actionsView.voteButton bk_whenTapped:^{
            [self setVoted:!self.voted animated:YES];
            
            if (self.voted) {
                // not voted -> vote it
                [BFAPI votePost:self.post completion:^(BOOL success, id responseObject) {
                    if (success) {
                        // NSLog(@"success upvoting!");
                    }
                }];
            }
            else {
                // not voted -> vote it
                [BFAPI unvotePost:self.post completion:^(BOOL success, id responseObject) {
                    if (success) {
                        // NSLog(@"success downvoting.");
                    }
                }];
            }
        }];
        [self.contentView addSubview:self.actionsView];
        
        self.lineSeparator.hidden = true;
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    UIEdgeInsets offset = postContentOffset;
    
    CGFloat yBottom = offset.top;
    
    if (![self.contextView isHidden]) {
        self.contextView.frame = CGRectMake(self.primaryAvatarView.frame.origin.x, postContentOffset.top - 4, self.frame.size.width - (self.primaryAvatarView.frame.origin.x + postContentOffset.right), postContextHeight);
        yBottom = self.contextView.frame.origin.y + self.contextView.frame.size.height + 4;
    }
    
    self.primaryAvatarView.frame = CGRectMake(12, yBottom, self.primaryAvatarView.frame.size.width, self.primaryAvatarView.frame.size.height);
    if (![self.secondaryAvatarView isHidden]) {
        self.secondaryAvatarView.frame = CGRectMake(self.primaryAvatarView.frame.origin.x + self.primaryAvatarView.frame.size.width - self.secondaryAvatarView.frame.size.width, self.primaryAvatarView.frame.origin.y + self.primaryAvatarView.frame.size.height - self.secondaryAvatarView.frame.size.height, self.secondaryAvatarView.frame.size.width, self.secondaryAvatarView.frame.size.height);
    }
    
    if (![self.moreButton isHidden]) {
        CGFloat moreButtonPadding = 12;
        CGFloat moreButtonWidth = self.moreButton.currentImage.size.width + (moreButtonPadding * 2);
        self.moreButton.frame = CGRectMake(self.frame.size.width - moreButtonWidth - postContentOffset.right + moreButtonPadding, yBottom - moreButtonPadding, moreButtonWidth, self.nameLabel.frame.size.height + (moreButtonPadding * 2));
    }
    
    CGSize dateLabelSize = [self.dateLabel.text boundingRectWithSize:CGSizeMake(100, self.actionsView.frame.size.height) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName: self.dateLabel.font} context:nil].size;
    self.dateLabel.frame = CGRectMake(([self.moreButton isHidden] ? self.frame.size.width - offset.right :  self.moreButton.frame.origin.x) - ceilf(dateLabelSize.width), yBottom, ceilf(dateLabelSize.width), self.dateLabel.frame.size.height);
    self.nameLabel.frame = CGRectMake(offset.left, yBottom, (self.dateLabel.frame.origin.x - 8) - offset.left, self.nameLabel.frame.size.height);
    yBottom = self.nameLabel.frame.origin.y + self.nameLabel.frame.size.height;
    
    // -- text view
    self.textView.frame = CGRectMake(offset.left, yBottom + 3, self.frame.size.width - offset.left - offset.right, self.textView.frame.size.height);
    if (self.post.attributes.simpleMessage.length > 0) {
        self.textView.tintColor = self.tintColor;
        [self.textView update];
        yBottom = self.textView.frame.origin.y + self.textView.frame.size.height;
    }
    
    BOOL hasImage = (self.post.attributes.media.count > 0 || self.post.attributes.attachments.media.count > 0); //self.post.images != nil && self.post.images.count > 0;
    self.imagesView.hidden = !hasImage;
    if (hasImage) {
        CGFloat imageHeight = [PostImagesView streamImageHeight];
        self.imagesView.frame = CGRectMake(offset.left, yBottom + 8, self.frame.size.width - offset.left - postContentOffset.right, imageHeight);
        
        yBottom = self.imagesView.frame.origin.y + self.imagesView.frame.size.height;
    }
    else {
        yBottom = self.textView.frame.origin.y + self.textView.frame.size.height;
    }
    
    if (self.linkAttachmentView) {
        [self.linkAttachmentView layoutSubviews];
        self.linkAttachmentView.frame = CGRectMake(offset.left, yBottom + 8, self.frame.size.width - offset.left - postContentOffset.right, [BFLinkAttachmentView heightForLink:self.linkAttachmentView.link width: self.frame.size.width-(postContentOffset.left+postContentOffset.right)]);
        
        yBottom = self.linkAttachmentView.frame.origin.y + self.linkAttachmentView.frame.size.height;
    }
    
    if (self.smartLinkAttachmentView) {
        [self.smartLinkAttachmentView layoutSubviews];
        self.smartLinkAttachmentView.frame = CGRectMake(offset.left, yBottom + 8, self.frame.size.width - offset.left - postContentOffset.right, [BFSmartLinkAttachmentView heightForSmartLink:self.smartLinkAttachmentView.link width: self.frame.size.width-(postContentOffset.left+postContentOffset.right)]);
        
        yBottom = self.smartLinkAttachmentView.frame.origin.y + self.smartLinkAttachmentView.frame.size.height;
    }
    
    if (self.campAttachmentView) {
        [self.campAttachmentView layoutSubviews];
        self.campAttachmentView.frame = CGRectMake(offset.left, yBottom + 8, self.frame.size.width - offset.left - postContentOffset.right, [BFCampAttachmentView heightForCamp:self.campAttachmentView.camp width: self.frame.size.width-(postContentOffset.left+postContentOffset.right)]);
        
        yBottom = self.campAttachmentView.frame.origin.y + self.campAttachmentView.frame.size.height;
    }
    
    if (self.userAttachmentView) {
        [self.userAttachmentView layoutSubviews];
        self.userAttachmentView.frame = CGRectMake(offset.left, yBottom + 8, self.frame.size.width - offset.left - postContentOffset.right, [BFUserAttachmentView heightForUser:self.userAttachmentView.user width: self.frame.size.width-(postContentOffset.left+postContentOffset.right)]);
        
        yBottom = self.userAttachmentView.frame.origin.y + self.userAttachmentView.frame.size.height;
    }
    
    if (self.postRemovedAttachmentView) {
        [self.postRemovedAttachmentView layoutSubviews];
        self.postRemovedAttachmentView.frame = CGRectMake(offset.left, yBottom + 3, self.frame.size.width - offset.left - postContentOffset.right, [BFPostDeletedAttachmentView heightForMessage:self.postRemovedAttachmentView.message width: self.frame.size.width-(postContentOffset.left+postContentOffset.right)]);
        
        yBottom = self.postRemovedAttachmentView.frame.origin.y + self.postRemovedAttachmentView.frame.size.height;
    }
    
    self.actionsView.frame = CGRectMake(self.nameLabel.frame.origin.x, yBottom + 8, self.frame.size.width - offset.left - postContentOffset.right, self.actionsView.frame.size.height);
    
    if (!self.lineSeparator.isHidden) {
         self.lineSeparator.frame = CGRectMake(0, self.frame.size.height - self.lineSeparator.frame.size.height, self.frame.size.width, self.lineSeparator.frame.size.height);
    }
    
    if (![self.topLine isHidden]) {
        self.topLine.frame = CGRectMake(self.primaryAvatarView.frame.origin.x + (self.primaryAvatarView.frame.size.width / 2) - (self.topLine.frame.size.width / 2), -2, 3, (self.primaryAvatarView.frame.origin.y - 4) + 2);
    }
    
     if (![self.bottomLine isHidden]) {
         self.bottomLine.frame = CGRectMake(self.primaryAvatarView.frame.origin.x + (self.primaryAvatarView.frame.size.width / 2) - (self.bottomLine.frame.size.width / 2), self.primaryAvatarView.frame.origin.y + self.primaryAvatarView.frame.size.height + 4, 3, self.frame.size.height - (self.primaryAvatarView.frame.origin.y + self.primaryAvatarView.frame.size.height + 4) + 2);
     }
}

// Setter method
/*
- (void)postTextViewDidDoubleTap:(PostTextView *)postTextView {
    if (postTextView != self.textView)
        return;
    
    [self setVoted:!self.voted withAnimation:VoteAnimationTypeAll];
}*/
- (void)setVoted:(BOOL)isVoted animated:(BOOL)animated {
    if (!animated || (isVoted != self.voted)) {
        self.voted = isVoted;
        
        [self.actionsView setVoted:isVoted animated:animated];
        
        void(^rippleAnimation)(void) = ^() {
            if (!self.voted)
                return;
            
            if (self.post.attributes.simpleMessage.length == 0)
                return;
            
            CGFloat bubbleDiamater = (self.frame.size.width > self.frame.size.height ? self.frame.size.width : self.frame.size.height) * 1.8;
            UIView *bubble = [[UIView alloc] initWithFrame:CGRectMake(0, 0, bubbleDiamater, bubbleDiamater)];
            bubble.userInteractionEnabled = false;
            bubble.center = self.textView.center;
            bubble.backgroundColor = [self.actionsView.voteButton.tintColor colorWithAlphaComponent:0.06];
            bubble.layer.cornerRadius = bubble.frame.size.height / 2;
            bubble.layer.masksToBounds = true;
            bubble.transform = CGAffineTransformMakeScale(0.01, 0.01);
            
            [self.contentView bringSubviewToFront:self.textView];
            [self.contentView insertSubview:bubble belowSubview:self.textView];
            
            [UIView animateWithDuration:animated?1.f:0 delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                bubble.transform = CGAffineTransformIdentity;
            } completion:nil];
            [UIView animateWithDuration:animated?1.f:0 delay:animated?0.1f:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                bubble.alpha = 0;
            } completion:^(BOOL finished) {
                [bubble removeFromSuperview];
            }];
        };
        
        if (animated) {
            rippleAnimation();
        }
    }
}

- (void)setPost:(Post *)post {
    if ([post toDictionary] != [_post toDictionary]) {
        _post = post;
        
        self.moreButton.tintColor = [UIColor bonfireSecondaryColor];
        self.dateLabel.textColor = [UIColor bonfireSecondaryColor];
        self.actionsView.tintColor = [UIColor bonfireSecondaryColor];
        self.contextView.tintColor = [UIColor bonfireSecondaryColor];
        
        self.moreButton.hidden = [self.post isRemoved];
        
        NSDictionary *context = (self.showContext ? [StreamPostCell contextForPost:post] : nil);
        self.contextView.hidden = !context;
        if (context) {
            self.contextView.attributedText = context[BFPostContextTextKey];
            self.contextView.icon = context[BFPostContextIconKey];
            
            [self.contextView.highlightView bk_whenTapped:^{
                if (post.attributes.parent) {
                    [Launcher openPost:post.attributes.parent withKeyboard:false];
                }
            }];
        }
        
        self.nameLabel.attributedText = [PostCell attributedCreatorStringForPost:_post includeTimestamp:false showCamptag:self.showCamptag primaryColor:nil];
        
        self.userInteractionEnabled = (!_post.tempId);
        if (self.contentView.alpha != 1 && !_post.tempId) {
            [UIView animateWithDuration:0.15f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.contentView.alpha = 1;
            } completion:^(BOOL finished) {
                
            }];
        }
        else {
            self.contentView.alpha = (_post.tempId ? 0.5 : 1);
        }
        
        if (_post.tempId) {
            self.dateLabel.text = @"1s";
        }
        else {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
            
            NSCalendar *gregorian = [[NSCalendar alloc]
                                     initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
            NSDateComponents *comps = [gregorian components: NSCalendarUnitMinute
                                                   fromDate: [formatter dateFromString:_post.attributes.createdAt]
                                                     toDate: [NSDate date]
                                                    options: 0];
             NSLog(@"days until token expiration:: %ld", (long)[comps day]);
            
            if ([comps day] < 1) {
                self.dateLabel.text = @"New";
            }
            else {
                self.dateLabel.text = @"";
            }
        }
        
        UIFont *font = [post isEmojiPost] ? [UIFont systemFontOfSize:textViewFont.pointSize*POST_EMOJI_SIZE_MULTIPLIER] : textViewFont;
        self.textView.messageLabel.font = font;
        self.textView.postId = self.post.identifier;
        
        [self.textView setMessage:self.post.attributes.simpleMessage entities:self.post.attributes.entities];
        
        if ([self.post.attributes.display.creator isEqualToString:POST_DISPLAY_CREATOR_CAMP] && self.post.attributes.postedIn) {
            if (self.primaryAvatarView.camp != _post.attributes.postedIn) {
                self.primaryAvatarView.camp = _post.attributes.postedIn;
            }
        }
        else {
            if (self.primaryAvatarView.user != _post.attributes.creator) {
                self.primaryAvatarView.user = _post.attributes.creator;
            }
        }
        self.primaryAvatarView.online = false;
        
        BOOL showSecondaryAvatarView = false;
        if (!self.primaryAvatarView.camp && post.attributes.postedIn != nil && self.showCamptag) {
            showSecondaryAvatarView = true;
            self.secondaryAvatarView.camp = post.attributes.postedIn;
        }
        
        self.secondaryAvatarView.hidden = !showSecondaryAvatarView;
        
        if (self.post.attributes.attachments.media.count > 0) {
            [self.imagesView setMedia:self.post.attributes.attachments.media];
        }
        else if (self.post.attributes.media.count > 0) {
            [self.imagesView setMedia:self.post.attributes.media];
        }
        else {
            [self.imagesView setMedia:@[]];
        }
        
        // smart link attachment
        if ([self.post hasLinkAttachment]) {
            // TODO: change this to self.post.attributes.attachments.link.attributes.attribution
            BOOL smartLink = [self.post.attributes.postedIn.attributes.display.format isEqualToString:CAMP_DISPLAY_FORMAT_CHANNEL];
            
            if (smartLink) {
                [self initSmartLinkAttachment];
                [self removeLinkAttachment];
            }
            else {
                [self initLinkAttachment];
                [self removeSmartLinkAttachment];
            }
        }
        else {
            [self removeSmartLinkAttachment];
            [self removeLinkAttachment];
        }
        
        // camp attachment
        if ([self.post hasCampAttachment]) {
            [self initCampAttachment];
        }
        else if (self.campAttachmentView) {
            [self removeCampAttachment];
        }
        
        // user attachment
        if ([self.post hasUserAttachment]) {
            [self initUserAttachment];
        }
        else if (self.userAttachmentView) {
            [self removeUserAttachment];
        }
        
        // post removed attachment
        if ([self.post isRemoved]) {
            [self initPostRemovedAttachment];
            
            // force hidden actions if a post is removed
            self.hideActions = true;
        }
        else if (self.postRemovedAttachmentView) {
            [self removePostRemovedAttachment];
        }
        
        self.actionsView.hidden = self.hideActions;
        if (![self.actionsView isHidden]) {
            self.actionsView.actionsType = PostActionsViewTypeConversation;
            
            [self setVoted:(self.post.attributes.context.post.vote != nil) animated:false];
            [self.actionsView setSummaries:post.attributes.summaries];
            
            BOOL canReply = ![post.attributes.creator isKindOfClass:[Bot class]] && [self.post.attributes.context.post.permissions canReply];
            self.actionsView.replyButton.alpha = canReply || self.post.tempId.length > 0 ? 1 : 0.5;
            self.actionsView.replyButton.userInteractionEnabled = canReply;
        }
        
        // self.bottomLine.hidden = self.post.attributes.summaries.replies.count == 0;
    }
}

+ (BOOL)showRepliesSnapshotForPost:(Post *)post {
    NSInteger summariesCount = post.attributes.summaries.replies.count;
    
    return (summariesCount > 0);
}
+ (CGFloat)heightForPost:(Post *)post showContext:(BOOL)showContext showActions:(BOOL)showActions {
    CGFloat height = postContentOffset.top;
    
    if ([post isRemoved]) {
        // force hidden actions if the post has been removed
        showActions = false;
    }
    
     BOOL hasContext = (showContext && [self contextForPost:post]);
     if (hasContext) {
         height = height - 4 + postContextHeight + 4;
     }
    
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    
    CGFloat nameHeight = 18; // 3pt padding underneath
    height += nameHeight;
    
    if (post.attributes.simpleMessage.length > 0) {
        // message
        UIFont *font = [post isEmojiPost] ? [UIFont systemFontOfSize:textViewFont.pointSize*POST_EMOJI_SIZE_MULTIPLIER] : textViewFont;
        
        CGFloat messageHeight = [PostTextView sizeOfBubbleWithMessage:post.attributes.simpleMessage withConstraints:CGSizeMake(screenWidth - postContentOffset.left - postContentOffset.right, CGFLOAT_MAX) font:font maxCharacters:[PostTextView entityBasedMaxCharactersForMessage:post.attributes.simpleMessage maxCharacters:STREAM_POST_MAX_CHARACTERS entities:post.attributes.entities] styleAsBubble:false].height;
        
        CGFloat textViewHeight = ceilf(messageHeight) + 3; // 3 on top
        height = height + textViewHeight;
    }
    
    // image
    BOOL hasImage = post.attributes.media.count > 0 || post.attributes.attachments.media.count > 0; // postAtIndex.images != nil && postAtIndex.images.count > 0;
    if (hasImage) {
        CGFloat imageHeight = [PostImagesView streamImageHeight];
        imageHeight = imageHeight + 8; // 8 above
        height = height + imageHeight;
    }
    
    BOOL hasLinkPreview = [post hasLinkAttachment];
    if (hasLinkPreview) {
        // TODO: change this to self.post.attributes.attachments.link.attributes.attribution
        BOOL smartLink = [post.attributes.postedIn.attributes.display.format isEqualToString:CAMP_DISPLAY_FORMAT_CHANNEL];
        
        CGFloat linkPreviewHeight;
        if (smartLink) {
            linkPreviewHeight = [BFSmartLinkAttachmentView heightForSmartLink:post.attributes.attachments.link  width:screenWidth-postContentOffset.left-postContentOffset.right];
        }
        else {
            linkPreviewHeight = [BFLinkAttachmentView heightForLink:post.attributes.attachments.link  width:screenWidth-postContentOffset.left-postContentOffset.right];
        }

        height = height + linkPreviewHeight + 8; // 8 above
    }
    
    BOOL hasCampAttachment = [post hasCampAttachment];
    if (hasCampAttachment) {
        Camp *camp = post.attributes.attachments.camp;
        
        CGFloat campAttachmentHeight = [BFCampAttachmentView heightForCamp:camp width:screenWidth-postContentOffset.left-postContentOffset.right];
        height = height + campAttachmentHeight + 8; // 8 above
    }
    
    BOOL hasUserAttachment = [post hasUserAttachment];
    if (hasUserAttachment) {
        User *user = post.attributes.attachments.user;
        
        CGFloat userAttachmentHeight = [BFUserAttachmentView heightForUser:user width:screenWidth-postContentOffset.left-postContentOffset.right];
        height = height + userAttachmentHeight + 8; // 8 above
    }
    
    BOOL hasPostRemovedAttachment = [post isRemoved];
    if (hasPostRemovedAttachment) {
        NSString *message = post.attributes.removedReason;
        
        CGFloat postRemovedAttachmentHeight = [BFPostDeletedAttachmentView heightForMessage:message width:screenWidth-postContentOffset.left-postContentOffset.right];
        height = height + postRemovedAttachmentHeight + 3 + 8; // 3 above (remember, there's no content if the post has been removed). add an additional 8 padding on the bottom
    }
    
    // details view
    CGFloat detailsHeight = (showActions ? 8 + POST_ACTIONS_VIEW_HEIGHT : 0); // 6 + 32; // 8 above
    height = height + detailsHeight + postContentOffset.bottom;
    
    CGFloat minHeight = postContentOffset.top + 48 + postContentOffset.bottom;
    
    return height > minHeight ? height : minHeight;
}

+ (NSDictionary *)contextForPost:(Post *)post {
    NSMutableAttributedString *attributedText;
    UIImage *icon;
    
    if (post.attributes.parent.attributes.creator.attributes.identifier.length > 0) {
        NSString *parentUsername = post.attributes.parent.attributes.creator.attributes.identifier;
        
        UIFont *font = [UIFont systemFontOfSize:15.f weight:UIFontWeightRegular];
        
        attributedText = [[NSMutableAttributedString alloc] initWithString:@"Replying to " attributes:@{NSFontAttributeName: font, NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor]}];
        
        NSAttributedString *attributedCreatorText;
        
        if ([parentUsername isEqualToString:[Session sharedInstance].currentUser.attributes.identifier]) {
            attributedCreatorText = [[NSAttributedString alloc] initWithString:@"you" attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:font.pointSize weight:UIFontWeightSemibold], NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor]}];
        }
        else {
            attributedCreatorText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"@%@", parentUsername] attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:15.f weight:UIFontWeightSemibold], NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor]}];
        }
        [attributedText appendAttributedString:attributedCreatorText];
        
//        // disclosure icon ( > )
//        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
//        attachment.image = [UIImage imageNamed:@"headerDetailDisclosureIcon"];
//        [attachment setBounds:CGRectMake(6, roundf(font.capHeight - attachment.image.size.height * .75)/2.f - 0.5, attachment.image.size.width * .75, attachment.image.size.height * .75)];
//        NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
//        [attributedText appendAttributedString:attachmentString];
        
        icon = [[UIImage imageNamed:@"notificationIndicator_reply"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    
    if (attributedText.length > 0 && icon) {
        return @{BFPostContextTextKey: attributedText, BFPostContextIconKey: icon};
    }
    
    return nil;
}

@end
