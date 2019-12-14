//
//  ExpandedPostCell.m
//  Hallway App
//
//  Created by Austin Valleskey on 3/10/18.
//  Copyright © 2018 Ingenious, Inc. All rights reserved.
//

#import "ExpandedPostCell.h"
#import <BlocksKit/BlocksKit+UIKit.h>
#import <SafariServices/SafariServices.h>
#import "NSDate+NVTimeAgo.h"
#import <HapticHelper/HapticHelper.h>
#import "Session.h"
#import "Launcher.h"
#import "UIColor+Palette.h"
#import <SDWebImage/SDImageCache.h>
#import "BFAlertController.h"

@implementation ExpandedPostCell

@synthesize post = _post;

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.nameLabel.hidden = true;
        
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenRect.size.width;
        
        self.contentView.frame = CGRectMake(0, 0, screenWidth, 100);
        self.contentView.layer.masksToBounds = false;
        
        self.replyingToButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.replyingToButton.frame = CGRectMake(expandedPostContentOffset.left, 0, self.contentView.frame.size.width - (expandedPostContentOffset.left + expandedPostContentOffset.right), 24);
        self.replyingToButton.backgroundColor = self.contentView.backgroundColor;
        [self.replyingToButton setTitleColor:[UIColor bonfireSecondaryColor] forState:UIControlStateNormal];
        self.replyingToButton.hidden = true;
        self.replyingToButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [self.contentView addSubview:self.replyingToButton];
        
        self.primaryAvatarView.frame = CGRectMake(12, 12, 48, 48);
        self.secondaryAvatarView.frame = CGRectMake(self.primaryAvatarView.frame.origin.x + self.primaryAvatarView.frame.size.width - self.secondaryAvatarView.frame.size.width, self.primaryAvatarView.frame.origin.y + self.primaryAvatarView.frame.size.height - self.secondaryAvatarView.frame.size.height, self.secondaryAvatarView.frame.size.width, self.secondaryAvatarView.frame.size.height);
        self.primaryAvatarView.openOnTap = true;
        
        self.creatorView = [[TappableView alloc] initWithFrame:CGRectMake(70, self.primaryAvatarView.frame.origin.y + (self.primaryAvatarView.frame.size.height / 2) - 16, 400, 32)];
        [self.creatorView bk_whenTapped:^{
            if ([self.post.attributes.display.creator isEqualToString:POST_DISPLAY_CREATOR_CAMP] && self.post.attributes.postedIn != nil) {
                [Launcher openCamp:self.post.attributes.postedIn];
            }
            else if (self.post.attributes.creatorBot != nil) {
                [Launcher openBot:self.post.attributes.creatorBot];
            }
            else if (self.post.attributes.creatorUser != nil) {
                [Launcher openProfile:self.post.attributes.creatorUser];
            }
        }];
        [self.contentView addSubview:self.creatorView];
        
        self.creatorTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 400, 16)];
        self.creatorTitleLabel.font = [UIFont systemFontOfSize:15.f weight:UIFontWeightSemibold];
        self.creatorTitleLabel.textColor = [UIColor bonfirePrimaryColor];
        [self.creatorView addSubview:self.creatorTitleLabel];
        
        self.creatorTagLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.creatorTitleLabel.frame.origin.y + self.creatorTitleLabel.frame.size.height + 2, self.creatorTitleLabel.frame.size.width, 16)];
        self.creatorTagLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightMedium];
        self.creatorTagLabel.textColor = [UIColor bonfireSecondaryColor];
        [self.creatorView addSubview:self.creatorTagLabel];
        
        self.postedInArrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"postedInTriangleIcon"]];
        self.postedInArrow.hidden = true;
        [self.contentView addSubview:self.postedInArrow];
        
        self.postedInButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.postedInButton.frame = CGRectMake(0, 0, 122, 36);
        self.postedInButton.layer.cornerRadius = self.postedInButton.frame.size.height / 2;
        self.postedInButton.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.postedInButton.backgroundColor = [UIColor bonfireDetailColor];
        [self.postedInButton setTitleColor:[UIColor bonfirePrimaryColor] forState:UIControlStateNormal];
        self.postedInButton.titleLabel.font = [UIFont systemFontOfSize:12.f weight:UIFontWeightSemibold];
        self.postedInButton.contentEdgeInsets = UIEdgeInsetsMake(0, 38, 0, 10);
        self.postedInButton.hidden = true;
        [self.postedInButton bk_whenTapped:^{
            if (self.post.attributes.postedIn != nil) {
                [Launcher openCamp:self.post.attributes.postedIn];
            }
        }];
        [self.postedInButton bk_addEventHandler:^(id sender) {
            [UIView animateWithDuration:0.3f delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.postedInButton.backgroundColor = [UIColor bonfireDetailHighlightedColor];
            } completion:nil];
        } forControlEvents:UIControlEventTouchDown];
        [self.postedInButton bk_addEventHandler:^(id sender) {
            [UIView animateWithDuration:0.3f delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.postedInButton.backgroundColor = [UIColor bonfireDetailColor];
            } completion:nil];
        } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
        
        BFAvatarView *postedInAvatarView = [[BFAvatarView alloc] initWithFrame:CGRectMake(4, 4, self.postedInButton.frame.size.height - 8, self.postedInButton.frame.size.height - 8)];
        postedInAvatarView.userInteractionEnabled = false;
        postedInAvatarView.dimsViewOnTap = false;
        postedInAvatarView.tag = 10;
        [self.postedInButton addSubview:postedInAvatarView];
        
        [self.contentView addSubview:self.postedInButton];
        
        // text view
        self.textView.frame = CGRectMake(expandedPostContentOffset.left, self.primaryAvatarView.frame.origin.y + self.primaryAvatarView.frame.size.height + 12, [UIScreen mainScreen].bounds.size.width - expandedPostContentOffset.right - expandedPostContentOffset.left, 200);
        self.textView.messageLabel.font = expandedTextViewFont;
        self.textView.messageLabel.selectable = true;
        self.textView.messageLabel.editable = true;
        self.textView.delegate = self;
        self.textView.maxCharacters = 10000;
        self.textView.postId = self.post.identifier;
                
        self.activityView = [[PostActivityView alloc] initWithFrame:CGRectMake(0, self.textView.frame.origin.y + self.textView.frame.size.height, self.frame.size.width, 30)];
        [self.contentView addSubview:self.activityView];
        
        // actions view
        self.actionsView = [[ExpandedPostActionsView alloc] initWithFrame:CGRectMake(0, 56, self.frame.size.width, expandedActionsViewHeight)];
        [self.actionsView.voteButton bk_whenTapped:^{
            [self setVoted:!self.voted withAnimation:true];
            
            if (self.voted) {
                [HapticHelper generateFeedback:FeedbackType_Notification_Success];
                
                // not voted -> vote it
                [BFAPI votePost:self.post completion:^(BOOL success, id responseObject) {
                    if (success) {
                        // NSLog(@"success upvoting!");
                    }
                }];
            }
            else {
                // voted -> unvote it
                [BFAPI unvotePost:self.post completion:^(BOOL success, id responseObject) {
                    if (success) {
                        // NSLog(@"success downvoting.");
                    }
                }];
            }
        }];
        [self.actionsView.shareButton bk_whenTapped:^{
            [Launcher openPostActions:self.post];
        }];
        [self.contentView addSubview:self.actionsView];
        
        self.moreButton.hidden = false;
                
        self.lineSeparator.hidden = false;
        self.lineSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
        [self bringSubviewToFront:self.lineSeparator];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
        
    self.contentView.frame = self.bounds;
    
    CGFloat yBottom = expandedPostContentOffset.top;
    
    self.primaryAvatarView.frame = CGRectMake(self.primaryAvatarView.frame.origin.x, yBottom, self.primaryAvatarView.frame.size.width, self.primaryAvatarView.frame.size.height);
    yBottom = self.primaryAvatarView.frame.origin.y + self.primaryAvatarView.frame.size.height + 16;
    
    if (![self.replyingToButton isHidden]) {
        self.replyingToButton.frame = CGRectMake(expandedPostContentOffset.left, yBottom, self.frame.size.width - (expandedPostContentOffset.left + expandedPostContentOffset.right), self.replyingToButton.frame.size.height);
        [self.replyingToButton viewWithTag:1].frame = CGRectMake(0, self.replyingToButton.frame.size.height - (1 / [UIScreen mainScreen].scale), self.replyingToButton.frame.size.width, (1 / [UIScreen mainScreen].scale));
        yBottom = self.replyingToButton.frame.origin.y + self.replyingToButton.frame.size.height;
    }
    
    if (![self.moreButton isHidden]) {
        self.moreButton.frame = CGRectMake(self.frame.size.width - 40, self.primaryAvatarView.frame.origin.y + self.primaryAvatarView.frame.size.height / 2 - 20, 40, 40);
    }
    
    CGFloat headerDetailsMaxWidth = (self.moreButton.frame.origin.x - self.creatorView.frame.origin.x);
    CGFloat creatorMaxWidth = headerDetailsMaxWidth * (self.post.attributes.postedIn != nil ? 0.6 : 1);
    
    CGFloat creatorTitleWidth = ceilf([self.creatorTitleLabel.attributedText boundingRectWithSize:CGSizeMake(creatorMaxWidth, self.creatorTitleLabel.frame.size.height) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin)  context:nil].size.width);
    self.creatorTitleLabel.frame = CGRectMake(0, self.creatorTitleLabel.frame.origin.y, creatorTitleWidth, self.creatorTitleLabel.frame.size.height);
    
    CGFloat creatorTagWidth = ceilf([self.creatorTagLabel.text boundingRectWithSize:CGSizeMake(creatorMaxWidth, self.creatorTagLabel.frame.size.height) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName: self.creatorTagLabel.font} context:nil].size.width);
    self.creatorTagLabel.frame = CGRectMake(0, self.creatorTagLabel.frame.origin.y, creatorTagWidth, self.creatorTagLabel.frame.size.height);
    
    self.creatorView.frame = CGRectMake(self.creatorView.frame.origin.x, self.primaryAvatarView.frame.origin.y + (self.primaryAvatarView.frame.size.height / 2) - (self.creatorView.frame.size.height / 2), (creatorTitleWidth > creatorTagWidth ? creatorTitleWidth : creatorTagWidth), self.creatorView.frame.size.height);
    
    if (![self.postedInArrow isHidden]) {
        self.postedInArrow.frame = CGRectMake(self.creatorView.frame.origin.x + self.creatorView.frame.size.width + 8, self.creatorView.frame.origin.y + (self.creatorView.frame.size.height / 2) - (self.postedInArrow.image.size.height / 2), self.postedInArrow.image.size.width, self.postedInArrow.image.size.height);
                
        CGFloat postedInButtonXOrigin = self.postedInArrow.frame.origin.x + self.postedInArrow.frame.size.width + 8;
        CGFloat postedInButtonWidth = self.postedInButton.intrinsicContentSize.width;
        if ([self.moreButton isHidden]) {
            if (postedInButtonWidth > (self.frame.size.width - expandedPostContentOffset.right - postedInButtonXOrigin)) {
                postedInButtonWidth = (self.frame.size.width - expandedPostContentOffset.right - postedInButtonXOrigin);
            }
        }
        else {
            if (postedInButtonWidth > (self.moreButton.frame.origin.x - postedInButtonXOrigin)) {
                postedInButtonWidth = (self.moreButton.frame.origin.x - postedInButtonXOrigin);
            }
        }
        
        self.postedInButton.frame = CGRectMake(postedInButtonXOrigin, self.creatorView.frame.origin.y + (self.creatorView.frame.size.height / 2) - (self.postedInButton.frame.size.height / 2), postedInButtonWidth, self.postedInButton.frame.size.height);
    }
    
    if ([self.post isRemoved]) {
        self.imagesView.hidden = true;
        
        if (self.postRemovedAttachmentView) {
            [self.postRemovedAttachmentView layoutSubviews];
            self.postRemovedAttachmentView.frame = CGRectMake(expandedPostContentOffset.left, yBottom, self.frame.size.width - expandedPostContentOffset.left - expandedPostContentOffset.right, [BFPostDeletedAttachmentView heightForMessage:self.postRemovedAttachmentView.message width: self.frame.size.width-(expandedPostContentOffset.left+expandedPostContentOffset.right)]);
            
//            yBottom = self.postRemovedAttachmentView.frame.origin.y + self.postRemovedAttachmentView.frame.size.height;
        }
    }
    else {
        // -- vote button
        BOOL isVoted = self.post.attributes.context.post.vote != nil;
        [self setVoted:isVoted withAnimation:false];
        
        // -- text view
        self.textView.frame = CGRectMake(expandedPostContentOffset.left, yBottom + ([self.replyingToButton isHidden] ? 0 : 4), self.frame.size.width - (expandedPostContentOffset.left + expandedPostContentOffset.right), self.textView.frame.size.height);
        if (self.post.attributes.simpleMessage.length > 0) {
            self.textView.tintColor = self.tintColor;
        }
        yBottom = self.textView.frame.origin.y + self.textView.frame.size.height;
        
        BOOL hasImage = (self.post.attributes.media.count > 0 || self.post.attributes.attachments.media.count > 0); //self.post.images != nil && self.post.images.count > 0;
        if (hasImage) {
            self.imagesView.hidden = false;
            
            CGFloat imageWidth = self.frame.size.width - (expandedPostContentOffset.left + expandedPostContentOffset.right);
            CGFloat imageHeight = expandedImageHeightDefault;
            
            if (self.post.attributes.attachments.media.count == 1 && [[self.post.attributes.attachments.media firstObject] isKindOfClass:[PostAttachmentsMedia class]]) {
                NSString *imageURL = self.post.attributes.attachments.media[0].attributes.hostedVersions.suggested.url;
                UIImage *memoryImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:imageURL];
                if (memoryImage) {
                    UIImage *memoryImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:imageURL];
                    if (memoryImage) {
                        CGFloat heightToWidthRatio = memoryImage.size.height / memoryImage.size.width;
                        imageHeight = roundf(imageWidth * heightToWidthRatio);
                        
                        if (imageHeight < 100) {
                            // NSLog(@"too small muchacho");
                            imageHeight = 100;
                        }
                        if (imageHeight > 480) {
                            // NSLog(@"too big muchacho");
                            imageHeight = 480;
                        }
                    }
                }
                else {
                    UIImage *diskImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:imageURL];
                    
                    if (diskImage) {
                        // disk image!
                        CGFloat heightToWidthRatio = diskImage.size.height / diskImage.size.width;
                        imageHeight = roundf(imageWidth * heightToWidthRatio);
                        
                        if (imageHeight < 100) {
                            // NSLog(@"too small muchacho");
                            imageHeight = 100;
                        }
                        if (imageHeight > 480) {
                            // NSLog(@"too big muchacho");
                            imageHeight = 480;
                        }
                    }
                }
            }
            
            self.imagesView.frame = CGRectMake(expandedPostContentOffset.left, yBottom + (self.textView.message.length > 0 || ![self.replyingToButton isHidden] ? 8 : 0), imageWidth, imageHeight);
            
            yBottom = self.imagesView.frame.origin.y + self.imagesView.frame.size.height;
        }
        else {
            self.imagesView.hidden = true;
        }
        
        if (self.linkAttachmentView) {
            [self.linkAttachmentView layoutSubviews];
            self.linkAttachmentView.frame = CGRectMake(expandedPostContentOffset.left, yBottom + 8, self.frame.size.width - expandedPostContentOffset.left - expandedPostContentOffset.right, [BFLinkAttachmentView heightForLink:self.linkAttachmentView.link width: self.frame.size.width-(expandedPostContentOffset.left+expandedPostContentOffset.right)]);
            
            yBottom = self.linkAttachmentView.frame.origin.y + self.linkAttachmentView.frame.size.height;
        }
        
        if (self.smartLinkAttachmentView) {
            [self.smartLinkAttachmentView layoutSubviews];
            self.smartLinkAttachmentView.frame = CGRectMake(expandedPostContentOffset.left, yBottom + 8, self.frame.size.width - expandedPostContentOffset.left - expandedPostContentOffset.right, [BFSmartLinkAttachmentView heightForSmartLink:self.smartLinkAttachmentView.link width: self.frame.size.width-(expandedPostContentOffset.left+expandedPostContentOffset.right) showActionButton:true]);
            
            yBottom = self.smartLinkAttachmentView.frame.origin.y + self.smartLinkAttachmentView.frame.size.height;
        }
        
        if (self.userAttachmentView) {
            [self.userAttachmentView layoutSubviews];
            self.userAttachmentView.frame = CGRectMake(expandedPostContentOffset.left, yBottom + 8, self.frame.size.width - expandedPostContentOffset.left - expandedPostContentOffset.right, [BFUserAttachmentView heightForUser:self.userAttachmentView.user width: self.frame.size.width-(expandedPostContentOffset.left+expandedPostContentOffset.right)]);
            
            yBottom = self.userAttachmentView.frame.origin.y + self.userAttachmentView.frame.size.height;
        }
        
        if (self.campAttachmentView) {
            [self.campAttachmentView layoutSubviews];
            self.campAttachmentView.frame = CGRectMake(expandedPostContentOffset.left, yBottom + 8, self.frame.size.width - expandedPostContentOffset.left - expandedPostContentOffset.right, [BFCampAttachmentView heightForCamp:self.campAttachmentView.camp width: self.frame.size.width-(expandedPostContentOffset.left+expandedPostContentOffset.right)]);
            
            yBottom = self.campAttachmentView.frame.origin.y + self.campAttachmentView.frame.size.height;
        }
        
        if (self.postAttachmentView) {
            [self.postAttachmentView layoutSubviews];
            self.postAttachmentView.frame = CGRectMake(expandedPostContentOffset.left, yBottom + 8, self.frame.size.width - expandedPostContentOffset.left - expandedPostContentOffset.right, [BFPostAttachmentView heightForPost:self.postAttachmentView.post width: self.frame.size.width-(expandedPostContentOffset.left+expandedPostContentOffset.right)]);
            
            yBottom = self.postAttachmentView.frame.origin.y + self.postAttachmentView.frame.size.height;
        }
        
        self.actionsView.frame = CGRectMake(expandedPostContentOffset.left, yBottom + 20, self.frame.size.width - (expandedPostContentOffset.left + expandedPostContentOffset.right), self.actionsView.frame.size.height);
        yBottom = self.actionsView.frame.origin.y + self.actionsView.frame.size.height;
        
        self.activityView.frame = CGRectMake(0, yBottom, self.frame.size.width, 30);
//        yBottom = self.activityView.frame.origin.y + self.activityView.frame.size.height;
        
        self.actionsView.topSeparator.frame = CGRectMake(0, self.actionsView.topSeparator.frame.origin.y, self.actionsView.frame.size.width, self.actionsView.topSeparator.frame.size.height);
        self.actionsView.bottomSeparator.frame = CGRectMake(-1 * self.actionsView.frame.origin.x, self.actionsView.frame.size.height - self.actionsView.bottomSeparator.frame.size.height, self.actionsView.frame.size.width + (self.actionsView.frame.origin.x * 2), self.actionsView.bottomSeparator.frame.size.height);
        // self.actionsView.middleSeparator.frame = CGRectMake(self.actionsView.frame.size.width / 2 - .5, 8, 1, self.actionsView.frame.siz e.height - 16);
        
        self.actionsView.replyButton.frame = CGRectMake(0, 0, self.actionsView.frame.size.width / 3, self.actionsView.frame.size.height);
        self.actionsView.voteButton.frame = CGRectMake(self.actionsView.replyButton.frame.size.width, 0, self.actionsView.frame.size.width / 3, self.actionsView.frame.size.height);
        self.actionsView.shareButton.frame = CGRectMake(self.actionsView.frame.size.width - (self.actionsView.frame.size.width / 3), 0, self.actionsView.frame.size.width / 3, self.actionsView.frame.size.height);
    }
        
    self.lineSeparator.frame = CGRectMake(0, self.frame.size.height - self.lineSeparator.frame.size.height,  self.frame.size.width, self.lineSeparator.frame.size.height);
    
    if (![self.topLine isHidden]) {
        self.topLine.frame = CGRectMake(self.primaryAvatarView.frame.origin.x + (self.primaryAvatarView.frame.size.width / 2) - (self.topLine.frame.size.width / 2), -2, 3, (self.primaryAvatarView.frame.origin.y - 4) + 2);
    }
}

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

// Setter method
- (void)postTextViewDidDoubleTap:(PostTextView *)postTextView {
    if (postTextView != self.textView)
        return;
    
    if (!self.voted) {
        [HapticHelper generateFeedback:FeedbackType_Notification_Success];
    }
    
    [self setVoted:!self.voted withAnimation:true];
}
- (void)setVoted:(BOOL)isVoted withAnimation:(BOOL)animated {
    if (!animated || (animated && isVoted != self.voted)) {
        self.voted = isVoted;
        
        if (self.voted) {
            [self.actionsView.voteButton setImage:[[UIImage imageNamed:@"boltIcon_active"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        }
        else {
            [self.actionsView.voteButton setImage:[[UIImage imageNamed:@"boltIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        }
    }
}

- (void)setPost:(Post *)post {
    if (post != _post) {
        _post = post;
        
        self.replyingToButton.hidden = !self.post.attributes.parent && self.post.attributes.thread.prevCursor.length == 0;
        if (![self.replyingToButton isHidden]) {
            UIFont *font = [UIFont systemFontOfSize:14.f weight:UIFontWeightRegular];
                    
            NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:((self.post.attributes.parent || self.post.attributes.thread.prevCursor) ? @"Replying to " : @"Loading...") attributes:@{NSFontAttributeName: font, NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor]}];
            
            if (self.post.attributes.parent) {
                NSAttributedString *attributedCreatorText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"@%@", post.attributes.parent.attributes.creator.attributes.identifier] attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:font.pointSize weight:UIFontWeightSemibold], NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor]}];
                [attributedText appendAttributedString:attributedCreatorText];
            }
            
            [self.replyingToButton setAttributedTitle:attributedText forState:UIControlStateNormal];
        }
        
        // set tint color
        Camp *postedInCamp = self.post.attributes.postedIn;
        if (postedInCamp != nil) {
            self.tintColor = [UIColor fromHex:self.post.attributes.postedIn.attributes.color];
        }
        else {
            self.tintColor = [UIColor fromHex:self.post.attributes.creator.attributes.color];
        }
        
        BOOL removed = [self.post isRemoved];
        self.actionsView.hidden = removed;
        self.activityView.hidden = removed;
        self.textView.hidden = removed;
        if (removed) {
            [self initPostRemovedAttachment];
            
            // remove unnceeded attachment views, if needed
            if (self.linkAttachmentView) {
                [self removeLinkAttachment];
            }
            if (self.smartLinkAttachmentView) {
                [self removeSmartLinkAttachment];
            }
            if (self.campAttachmentView) {
                [self removeCampAttachment];
            }
            if (self.userAttachmentView) {
                [self removeUserAttachment];
            }
            if (self.postAttachmentView) {
                [self removePostAttachment];
            }
        }
        else {
            UIFont *font = [post isEmojiPost] ? [UIFont systemFontOfSize:ceilf(expandedTextViewFont.pointSize*POST_EMOJI_SIZE_MULTIPLIER)] : expandedTextViewFont;
            self.textView.messageLabel.font = font;
            self.textView.postId = self.post.identifier;
            
            [self.textView setMessage:self.post.attributes.simpleMessage entities:self.post.attributes.entities];
            
            NSArray *media;
            if (self.post.attributes.attachments.media.count > 0) {
                media = self.post.attributes.attachments.media;
            }
            else if (self.post.attributes.media.count > 0) {
                media = self.post.attributes.media;
            }
            else {
                media = @[];
            }
            [self.imagesView setMedia:media];
            
            // smart link attachment
            if ([self.post hasLinkAttachment]) {
                if ([self.post.attributes.attachments.link isSmartLink]) {
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
            
            // post attachment
            if ([self.post hasPostAttachment]) {
                [self initPostAttachment];
            }
            else if (self.postAttachmentView) {
                [self removePostAttachment];
            }
            
            // post removed attachment
            if (self.postRemovedAttachmentView) {
                [self removePostRemovedAttachment];
            }
            
            UIColor *theme;
            if (postedInCamp) {
                theme = [UIColor fromHex:self.post.attributes.postedIn.attributes.color adjustForOptimalContrast:true];
            }
            else {
                theme = [UIColor fromHex:self.post.attributes.creator.attributes.color adjustForOptimalContrast:true];
            }
            self.activityView.post = self.post;
            self.activityView.backgroundColor = [theme colorWithAlphaComponent:0.04];
            self.activityView.tintColor = theme;
            self.actionsView.tintColor = theme;
        }
                
        NSString *creatorTitle = @"Anonymous User";
        NSString *creatorTag = @"@anonymous";
        if ([self.post.attributes.display.creator isEqualToString:POST_DISPLAY_CREATOR_CAMP] && self.post.attributes.postedIn != nil) {
            creatorTitle = self.post.attributes.postedIn.attributes.title;
            if (self.post.attributes.postedIn.attributes.identifier) {
                creatorTag = [@"#" stringByAppendingString:self.post.attributes.postedIn.attributes.identifier];
            }
            
            self.postedInButton.hidden =
            self.postedInArrow.hidden  = YES;
        }
        else {
            NSString *timeAgo;
            if (_post.tempId) {
                timeAgo = @"1s";
            }
            else {
                timeAgo = [NSDate mysqlDatetimeFormattedAsTimeAgo:_post.attributes.createdAt withForm:TimeAgoShortForm];
            }
            
            creatorTitle = self.post.attributes.creator.attributes.displayName;
            if (self.post.attributes.creator.attributes.identifier) {
//                creatorTag = [NSString stringWithFormat:@"%@ · %@", [@"@" stringByAppendingString:self.post.attributes.creator.attributes.identifier], timeAgo];
                creatorTag = [NSString stringWithFormat:@"%@", [@"@" stringByAppendingString:self.post.attributes.creator.attributes.identifier]];
            }
            
            self.postedInButton.hidden =
            self.postedInArrow.hidden  = !postedInCamp;
        }
        
        if (creatorTitle) {
            UIFont *creatorTitleFont = [UIFont systemFontOfSize:15.f weight:UIFontWeightSemibold];
            NSMutableAttributedString *attributedCreatorTitle = [[NSMutableAttributedString alloc] initWithString:creatorTitle attributes:@{NSFontAttributeName:creatorTitleFont}];
            BOOL isVerified = [self.post.attributes.creator isVerified];
            if (isVerified) {
                NSMutableAttributedString *spacer = [[NSMutableAttributedString alloc] initWithString:@" "];
                [spacer addAttribute:NSFontAttributeName value:creatorTitleFont range:NSMakeRange(0, spacer.length)];
                [attributedCreatorTitle appendAttributedString:spacer];
                
                // verified icon ☑️
                NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
                attachment.image = [UIImage imageNamed:@"verifiedIcon_small"];
                [attachment setBounds:CGRectMake(0, roundf(creatorTitleFont.capHeight - attachment.image.size.height)/2.f, attachment.image.size.width, attachment.image.size.height)];
                
                NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
                [attributedCreatorTitle appendAttributedString:attachmentString];
            }
            self.creatorTitleLabel.attributedText = attributedCreatorTitle;
        }
        else {
            self.creatorTitleLabel.text = @"";
        }
        
        self.creatorTagLabel.text = creatorTag;
        
        if (![self.postedInButton isHidden]) {
            NSString *identifier;
            if (self.post.attributes.postedIn.attributes.identifier.length > 0) {
                identifier = [@"#" stringByAppendingString:self.post.attributes.postedIn.attributes.identifier];
            }
            else {
                identifier = self.post.attributes.postedIn.attributes.title;
            }
            [self.postedInButton setTitle:identifier forState:UIControlStateNormal];
            
            BFAvatarView *postedInAvatarView = [self.postedInButton viewWithTag:10];
            postedInAvatarView.camp = postedInCamp;
        }
        
        if ([self.post.attributes.display.creator isEqualToString:POST_DISPLAY_CREATOR_CAMP] && self.post.attributes.postedIn) {
            if (self.primaryAvatarView.camp != _post.attributes.postedIn) {
                self.primaryAvatarView.camp = _post.attributes.postedIn;
            }
        }
        else {
            if (self.primaryAvatarView.user != _post.attributes.creator && self.primaryAvatarView.bot != _post.attributes.creator) {
                if (_post.attributes.creatorUser) {
                    self.primaryAvatarView.user = _post.attributes.creatorUser;
                }
                else if (_post.attributes.creatorBot) {
                    self.primaryAvatarView.bot = _post.attributes.creatorBot;
                }
            }
        }
        self.primaryAvatarView.online = false;
        
        BOOL showSecondaryAvatarView = false;
        if ([post.attributes.display.creator isEqualToString:POST_DISPLAY_CREATOR_CAMP] && post.attributes.postedIn != nil) {
            self.secondaryAvatarView.camp = post.attributes.postedIn;
            // showSecondaryAvatarView = true;
        }
        self.secondaryAvatarView.hidden = !showSecondaryAvatarView;
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    
}

+ (CGFloat)heightForPost:(Post *)post width:(CGFloat)contentWidth {
    // name @username • 2hr
    CGFloat avatarHeight = 48; // 2pt padding underneath
    CGFloat avatarBottomPadding = 16;
    
    CGFloat height = avatarHeight + avatarBottomPadding;
    
    BOOL hasParentPost = post.attributes.parent || post.attributes.thread.prevCursor.length > 0;
    if (hasParentPost) {
        height += 24 + (post.attributes.message.length > 0 ? 0 : 4);
    }
    
    BOOL removed = [post isRemoved];
    if (removed) {
        height += [BFPostDeletedAttachmentView heightForMessage:post.attributes.removedReason width:contentWidth-expandedPostContentOffset.left-expandedPostContentOffset.right];
        
        height += 16; // bottom padding
    }
    else {
        // message
        BOOL hasMessage = post.attributes.simpleMessage.length > 0;
        if (hasMessage) {
           UIFont *font = [post isEmojiPost] ? [UIFont systemFontOfSize:ceilf(expandedTextViewFont.pointSize*POST_EMOJI_SIZE_MULTIPLIER)] : expandedTextViewFont;
            CGFloat messageHeight = [PostTextView sizeOfBubbleWithMessage:post.attributes.simpleMessage withConstraints:CGSizeMake(contentWidth - expandedPostContentOffset.left - expandedPostContentOffset.right, CGFLOAT_MAX) font:font maxCharacters:[PostTextView entityBasedMaxCharactersForMessage:post.attributes.simpleMessage maxCharacters:CGFLOAT_MAX entities:post.attributes.entities] styleAsBubble:false].height;
            height = height + messageHeight + (hasParentPost ? 4 : 0);
        }
        
        // image
        BOOL hasImage = (post.attributes.media.count > 0 || post.attributes.attachments.media.count > 0);
        if (hasImage && (hasMessage || hasParentPost)) {
            // spacing between message and image
            height = height + 8;
        }
        
        CGFloat imageWidth = contentWidth - (expandedPostContentOffset.left + expandedPostContentOffset.right);
        CGFloat imageHeight = expandedImageHeightDefault;
        
        if (post.attributes.attachments.media.count == 1 && [[post.attributes.attachments.media firstObject] isKindOfClass:[PostAttachmentsMedia class]]) {
            NSString *imageURL = post.attributes.attachments.media[0].attributes.hostedVersions.suggested.url;
            
            UIImage *memoryImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:imageURL];
            if (memoryImage) {
                UIImage *memoryImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:imageURL];
                if (memoryImage) {
                    CGFloat heightToWidthRatio = memoryImage.size.height / memoryImage.size.width;
                    imageHeight = roundf(imageWidth * heightToWidthRatio);
                    
                    if (imageHeight < 100) {
                        // NSLog(@"too small muchacho");
                        imageHeight = 100;
                    }
                    if (imageHeight > 480) {
                        // NSLog(@"too big muchacho");
                        imageHeight = 480;
                    }
                }
            }
            else {
                UIImage *diskImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:imageURL];
                
                if (diskImage) {
                    // disk image!
                    CGFloat heightToWidthRatio = diskImage.size.height / diskImage.size.width;
                    imageHeight = MAX(MIN(100, roundf(imageWidth * heightToWidthRatio)), 480);
                    
                    if (imageHeight < 100) {
                        imageHeight = 100;
                    }
                    else if (imageHeight > 480) {
                        imageHeight = 480;
                    }
                }
            }
        }
        if (hasImage) {
            height += imageHeight;
        }
        
        // 4 on top and 4 on bottom
        if ([post hasLinkAttachment]) {
            CGFloat linkPreviewHeight;
            if ([post.attributes.attachments.link isSmartLink]) {
                linkPreviewHeight = [BFSmartLinkAttachmentView heightForSmartLink:post.attributes.attachments.link  width:contentWidth-expandedPostContentOffset.left-expandedPostContentOffset.right showActionButton:true];
            }
            else {
                linkPreviewHeight = [BFLinkAttachmentView heightForLink:post.attributes.attachments.link  width:contentWidth-expandedPostContentOffset.left-expandedPostContentOffset.right];
            }
            
            height += linkPreviewHeight + 8; // 8 above
        }
        
        if ([post hasCampAttachment]) {
            Camp *camp = post.attributes.attachments.camp;
            
            CGFloat campAttachmentHeight = [BFCampAttachmentView heightForCamp:camp width:contentWidth-expandedPostContentOffset.left-expandedPostContentOffset.right];
            height = height + campAttachmentHeight + 8; // 8 above
        }
        
        if ([post hasUserAttachment]) {
            User *user = post.attributes.attachments.user;
            
            CGFloat userAttachmentHeight = [BFUserAttachmentView heightForUser:user width:contentWidth-expandedPostContentOffset.left-expandedPostContentOffset.right];
            height = height + userAttachmentHeight + 8; // 8 above
        }
        
        if ([post hasPostAttachment]) {
            Post *quotedPost = post.attributes.attachments.post;
            
            CGFloat postAttachmentHeight = [BFPostAttachmentView heightForPost:quotedPost width:contentWidth-expandedPostContentOffset.left-expandedPostContentOffset.right];
            height += postAttachmentHeight + 8; // 8 above
        }
        
        // actions
        CGFloat actionsHeight = 20 + expandedActionsViewHeight; // 12 = padding above actions view
        height += actionsHeight;
        
        CGFloat activityHeight = 30;
        height += activityHeight;
    }
    
    return expandedPostContentOffset.top + height + expandedPostContentOffset.bottom; // 1 = line separator
}

@end
