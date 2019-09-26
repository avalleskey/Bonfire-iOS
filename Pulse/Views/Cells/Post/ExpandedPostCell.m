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

@implementation ExpandedPostCell

@synthesize post = _post;

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.nameLabel.hidden = true;
        
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenRect.size.width;
        
        self.contentView.frame = CGRectMake(0, 0, screenWidth, 100);
        self.contentView.layer.masksToBounds = false;
        
        self.replyingToButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.replyingToButton.frame = CGRectMake(0, 0, self.contentView.frame.size.width, 30);
        [self.replyingToButton setImage:[UIImage imageNamed:@"replyingToUpArrow"] forState:UIControlStateNormal];
        self.replyingToButton.backgroundColor = self.contentView.backgroundColor;
        [self.replyingToButton setTitleColor:[UIColor bonfireSecondaryColor] forState:UIControlStateNormal];
        [self.replyingToButton setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 8)];
        [self.replyingToButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 8, 0, 0)];
        UIView *replyingToSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, self.replyingToButton.frame.size.height - (1 / [UIScreen mainScreen].scale), self.frame.size.width, (1 / [UIScreen mainScreen].scale))];
        replyingToSeparator.tag = 1;
        replyingToSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
        [self.replyingToButton addSubview:replyingToSeparator];
        self.replyingToButton.hidden = true;
        [self.contentView addSubview:self.replyingToButton];
        
        self.primaryAvatarView.frame = CGRectMake(12, 12, 48, 48);
        self.secondaryAvatarView.frame = CGRectMake(self.primaryAvatarView.frame.origin.x + self.primaryAvatarView.frame.size.width - self.secondaryAvatarView.frame.size.width, self.primaryAvatarView.frame.origin.y + self.primaryAvatarView.frame.size.height - self.secondaryAvatarView.frame.size.height, self.secondaryAvatarView.frame.size.width, self.secondaryAvatarView.frame.size.height);
        self.primaryAvatarView.openOnTap = true;
        
        self.creatorView = [[TappableView alloc] initWithFrame:CGRectMake(70, self.primaryAvatarView.frame.origin.y + (self.primaryAvatarView.frame.size.height / 2) - 16, 400, 32)];
        [self.creatorView bk_whenTapped:^{
            if ([self.post.attributes.status.display.creator isEqualToString:POST_DISPLAY_CREATOR_CAMP] && self.post.attributes.status.postedIn != nil) {
                [Launcher openCamp:self.post.attributes.status.postedIn];
            }
            else if (self.post.attributes.details.creator != nil) {
                [Launcher openProfile:self.post.attributes.details.creator];
            }
        }];
        [self.contentView addSubview:self.creatorView];
        
        self.creatorTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 400, 16)];
        self.creatorTitleLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightBold];
        self.creatorTitleLabel.textColor = [UIColor bonfirePrimaryColor];
        [self.creatorView addSubview:self.creatorTitleLabel];
        
        self.creatorTagLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.creatorTitleLabel.frame.origin.y + self.creatorTitleLabel.frame.size.height + 2, self.creatorTitleLabel.frame.size.width, 14)];
        self.creatorTagLabel.font = [UIFont systemFontOfSize:12.f weight:UIFontWeightSemibold];
        self.creatorTagLabel.textColor = [UIColor bonfireSecondaryColor];
        [self.creatorView addSubview:self.creatorTagLabel];
        
        self.postedInArrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"postedInTriangleIcon-1"]];
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
            if (self.post.attributes.status.postedIn != nil) {
                [Launcher openCamp:self.post.attributes.status.postedIn];
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
        self.textView.delegate = self;
        self.textView.maxCharacters = 10000;
        self.textView.postId = self.post.identifier;
        
        self.dateLabel.hidden = true;
        
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
            [Launcher sharePost:self.post];
        }];
        [self.contentView addSubview:self.actionsView];
        
        // image view
        // self.pictureView = [[UIImageView alloc] initWithFrame:CGRectMake(self.textView.frame.origin.x, 56, self.textView.frame.size.width, 120)];
        self.imagesView.layer.cornerRadius = 16.f;
        
        self.lineSeparator.hidden = false;
        self.lineSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
        [self bringSubviewToFront:self.lineSeparator];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    NSLog(@"layout those subviews boi");
    
    self.contentView.frame = self.bounds;
    
    CGFloat yBottom = ([self.replyingToButton isHidden] ? 0 : self.replyingToButton.frame.size.height);
    
    if (![self.replyingToButton isHidden]) {
        self.replyingToButton.frame = CGRectMake(0, 0, self.frame.size.width, self.replyingToButton.frame.size.height);
        [self.replyingToButton viewWithTag:1].frame = CGRectMake(0, self.replyingToButton.frame.size.height - (1 / [UIScreen mainScreen].scale), self.replyingToButton.frame.size.width, (1 / [UIScreen mainScreen].scale));
    }
    
    self.primaryAvatarView.frame = CGRectMake(self.primaryAvatarView.frame.origin.x, yBottom + 12, self.primaryAvatarView.frame.size.width, self.primaryAvatarView.frame.size.height);
    
    // -- vote button
    BOOL isVoted = self.post.attributes.context.post.vote != nil;
    [self setVoted:isVoted withAnimation:false];
    
    // -- text view
    self.textView.frame = CGRectMake(expandedPostContentOffset.left, self.primaryAvatarView.frame.origin.y + self.primaryAvatarView.frame.size.height + 12, self.frame.size.width - (expandedPostContentOffset.left + expandedPostContentOffset.right), self.textView.frame.size.height);
    if (self.post.attributes.details.simpleMessage.length > 0) {
        self.textView.tintColor = self.tintColor;
    }
    yBottom = self.textView.frame.origin.y + self.textView.frame.size.height;
    
    if (![self.moreButton isHidden]) {
        CGFloat moreButtonPadding = 12;
        CGFloat moreButtonWidth = self.moreButton.currentImage.size.width + (moreButtonPadding * 2);
        self.moreButton.frame = CGRectMake(self.frame.size.width - moreButtonWidth - expandedPostContentOffset.right + moreButtonPadding, (self.primaryAvatarView.frame.origin.y + self.primaryAvatarView.frame.size.height / 2) - 20 - moreButtonPadding, moreButtonWidth, 40 + (moreButtonPadding * 2));
    }
    
    CGFloat headerDetailsMaxWidth = (self.moreButton.frame.origin.x - self.creatorView.frame.origin.x);
    CGFloat creatorMaxWidth = headerDetailsMaxWidth * (self.post.attributes.status.postedIn != nil ? 0.6 : 1);
    
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
    
    
    BOOL hasImage = (self.post.attributes.details.media.count > 0 || self.post.attributes.details.attachments.media.count > 0); //self.post.images != nil && self.post.images.count > 0;
    if (hasImage) {
        self.imagesView.hidden = false;
        
        CGFloat imageWidth = self.frame.size.width - (expandedPostContentOffset.left + expandedPostContentOffset.right);
        CGFloat imageHeight = expandedImageHeightDefault;
        
        if (self.post.attributes.details.attachments.media.count == 1 && [[self.post.attributes.details.attachments.media firstObject] isKindOfClass:[PostAttachmentsMedia class]]) {
            NSString *imageURL = self.post.attributes.details.attachments.media[0].attributes.hostedVersions.suggested.url;
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
        
        self.imagesView.frame = CGRectMake(expandedPostContentOffset.left, yBottom + (self.textView.message.length > 0 ? 8 : 0), imageWidth, imageHeight);
        
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
    
    // -- actions view
    self.actionsView.frame = CGRectMake(expandedPostContentOffset.left, yBottom + 16, self.frame.size.width - (expandedPostContentOffset.left + expandedPostContentOffset.right), self.actionsView.frame.size.height);
    
    self.activityView.frame = CGRectMake(0, self.actionsView.frame.origin.y + self.actionsView.frame.size.height, self.frame.size.width, 30);
    
    self.lineSeparator.frame = CGRectMake(0, self.activityView.frame.origin.y + self.activityView.frame.size.height - self.lineSeparator.frame.size.height, self.frame.size.width, self.lineSeparator.frame.size.height);
    
    self.actionsView.topSeparator.frame = CGRectMake(0, self.actionsView.topSeparator.frame.origin.y, self.actionsView.frame.size.width, self.actionsView.topSeparator.frame.size.height);
    self.actionsView.bottomSeparator.frame = CGRectMake(-self.actionsView.frame.origin.x, self.actionsView.frame.size.height - self.actionsView.bottomSeparator.frame.size.height, self.actionsView.frame.size.width + (self.actionsView.frame.origin.x * 2), self.actionsView.bottomSeparator.frame.size.height);
    // self.actionsView.middleSeparator.frame = CGRectMake(self.actionsView.frame.size.width / 2 - .5, 8, 1, self.actionsView.frame.siz e.height - 16);
    
    self.actionsView.replyButton.frame = CGRectMake(0, 0, self.actionsView.frame.size.width / 3, self.actionsView.frame.size.height);
    self.actionsView.voteButton.frame = CGRectMake(self.actionsView.replyButton.frame.size.width, 0, self.actionsView.frame.size.width / 3, self.actionsView.frame.size.height);
    self.actionsView.shareButton.frame = CGRectMake(self.actionsView.frame.size.width - (self.actionsView.frame.size.width / 3), 0, self.actionsView.frame.size.width / 3, self.actionsView.frame.size.height);
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
        
        if (animated && self.voted) {
            [UIView animateWithDuration:1.9f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
                self.actionsView.voteButton.transform = CGAffineTransformMakeScale(1.2, 1.2);
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:1.2f delay:0.2f usingSpringWithDamping:0.4f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
                    self.actionsView.voteButton.transform = CGAffineTransformMakeScale(1, 1);
                } completion:nil];
            }];
        }
        
        if (self.voted) {
            [self.actionsView.voteButton setImage:[[UIImage imageNamed:@"boltIcon_active"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        }
        else {
            [self.actionsView.voteButton setImage:[[UIImage imageNamed:@"boltIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        }
    }
}

- (void)setPost:(Post *)post {
    if ([post toDictionary] != [_post toDictionary]) {
        _post = post;
        
        self.replyingToButton.hidden = self.post.attributes.details.parentId == 0;
        if (![self.replyingToButton isHidden]) {
            UIFont *font = [UIFont systemFontOfSize:12.f weight:UIFontWeightRegular];
                    
            NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:@"Replying to " attributes:@{NSFontAttributeName: font, NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor]}];
            
            NSAttributedString *attributedCreatorText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"@%@", post.attributes.details.parentUsername] attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:font.pointSize weight:UIFontWeightSemibold], NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor]}];
            [attributedText appendAttributedString:attributedCreatorText];
            
            [self.replyingToButton setAttributedTitle:attributedText forState:UIControlStateNormal];
        }
        
        // set tint color
        Camp *postedInCamp = self.post.attributes.status.postedIn;
        if (postedInCamp != nil) {
            self.tintColor = [UIColor fromHex:self.post.attributes.status.postedIn.attributes.details.color];
        }
        else {
            self.tintColor = [UIColor fromHex:self.post.attributes.details.creator.attributes.details.color];
        }
        
        UIFont *font = [post isEmojiPost] ? [UIFont systemFontOfSize:expandedTextViewFont.pointSize*POST_EMOJI_SIZE_MULTIPLIER] : expandedTextViewFont;
        self.textView.messageLabel.font = font;
        self.textView.postId = self.post.identifier;
        
        [self.textView setMessage:self.post.attributes.details.simpleMessage entities:self.post.attributes.details.entities];
        
        // todo: activity view init views
        self.activityView.post = self.post;
        
        //BOOL isReply = _post.attributes.details.parentId.length > 0;
        
        NSString *creatorTitle = @"Anonymous User";
        NSString *creatorTag = @"@anonymous";
        if ([self.post.attributes.status.display.creator isEqualToString:POST_DISPLAY_CREATOR_CAMP] && self.post.attributes.status.postedIn != nil) {
            creatorTitle = self.post.attributes.status.postedIn.attributes.details.title;
            if (self.post.attributes.status.postedIn.attributes.details.identifier) {
                creatorTag = [@"#" stringByAppendingString:self.post.attributes.status.postedIn.attributes.details.identifier];
            }
            
            self.postedInButton.hidden =
            self.postedInArrow.hidden  = YES;
        }
        else {
            creatorTitle = self.post.attributes.details.creator.attributes.details.displayName;
            if (self.post.attributes.details.creator.attributes.details.identifier) {
                creatorTag = [@"@" stringByAppendingString:self.post.attributes.details.creator.attributes.details.identifier];
            }
            
            self.postedInButton.hidden =
            self.postedInArrow.hidden  = !postedInCamp;
        }
        
        if (creatorTitle) {
            UIFont *creatorTitleFont = [UIFont systemFontOfSize:14.f weight:UIFontWeightBold];
            NSMutableAttributedString *attributedCreatorTitle = [[NSMutableAttributedString alloc] initWithString:creatorTitle attributes:@{NSFontAttributeName:creatorTitleFont}];
            BOOL isVerified = [self.post.attributes.details.creator isVerified];
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
        
        self.creatorTagLabel.text   = creatorTag;
        
        if (![self.postedInButton isHidden]) {
            if (self.post.attributes.status.postedIn.attributes.details.identifier.length > 0) {
                NSString *identifier = self.post.attributes.status.postedIn.attributes.details.title;
                if (self.post.attributes.status.postedIn.attributes.details.identifier.length > 0) {
                    identifier = [@"#" stringByAppendingString:self.post.attributes.status.postedIn.attributes.details.identifier];
                }
                [self.postedInButton setTitle:identifier forState:UIControlStateNormal];
            }
            
            BFAvatarView *postedInAvatarView = [self.postedInButton viewWithTag:10];
            postedInAvatarView.camp = postedInCamp;
        }
        
        if (self.primaryAvatarView.user != _post.attributes.details.creator) {
            self.primaryAvatarView.user = _post.attributes.details.creator;
        }
        self.primaryAvatarView.online = false;
        
        BOOL showSecondaryAvatarView = false;
        if ([post.attributes.status.display.creator isEqualToString:POST_DISPLAY_CREATOR_CAMP] && post.attributes.status.postedIn != nil) {
            self.secondaryAvatarView.camp = post.attributes.status.postedIn;
            // showSecondaryAvatarView = true;
        }
        self.secondaryAvatarView.hidden = !showSecondaryAvatarView;
        
        NSArray *media;
        if (self.post.attributes.details.attachments.media.count > 0) {
            media = self.post.attributes.details.attachments.media;
        }
        else if (self.post.attributes.details.media.count > 0) {
            media = self.post.attributes.details.media;
        }
        else {
            media = @[];
        }
        
        if ([self.post hasLinkAttachment]) {
            [self initLinkAttachment];
        }
        else if (self.linkAttachmentView) {
            [self removeLinkAttachment];
        }
        
        UIColor *theme;
        if (postedInCamp) {
            theme = [UIColor fromHex:self.post.attributes.status.postedIn.attributes.details.color];
        }
        else {
            theme = [UIColor fromHex:self.post.attributes.details.creator.attributes.details.color];
        }
        self.activityView.backgroundColor = [theme colorWithAlphaComponent:0.06f];
        self.activityView.tintColor = theme;
        
        [self.imagesView setMedia:media];
    }
}

+ (CGFloat)heightForPost:(Post *)post width:(CGFloat)contentWidth {
    CGFloat height = (post.attributes.details.parentId != 0 ? 30 : 0);
    
    // name @username • 2hr
    CGFloat avatarHeight = 48; // 2pt padding underneath
    CGFloat avatarBottomPadding = 12; //15 + 14; // 14pt padding underneath
    
    height = height + avatarHeight + avatarBottomPadding;
    
    // message
    BOOL hasMessage = post.attributes.details.simpleMessage.length > 0;
    if (hasMessage) {
        UIFont *font = [post isEmojiPost] ? [UIFont systemFontOfSize:expandedTextViewFont.pointSize*POST_EMOJI_SIZE_MULTIPLIER] : expandedTextViewFont;
        CGFloat messageHeight = [PostTextView sizeOfBubbleWithMessage:post.attributes.details.simpleMessage withConstraints:CGSizeMake(contentWidth - expandedPostContentOffset.left - expandedPostContentOffset.right, CGFLOAT_MAX) font:font maxCharacters:[PostTextView entityBasedMaxCharactersForMessage:post.attributes.details.simpleMessage maxCharacters:CGFLOAT_MAX entities:post.attributes.details.entities]].height;
        height = height + messageHeight;
    }
    
    // image
    BOOL hasImage = (post.attributes.details.media.count > 0 || post.attributes.details.attachments.media.count > 0);
    if (hasMessage && hasImage) {
        // spacing between message and image
        height = height + 8;
    }
    
    CGFloat imageWidth = contentWidth - (expandedPostContentOffset.left + expandedPostContentOffset.right);
    CGFloat imageHeight = expandedImageHeightDefault;
    
    if (post.attributes.details.attachments.media.count == 1 && [[post.attributes.details.attachments.media firstObject] isKindOfClass:[PostAttachmentsMedia class]]) {
        NSString *imageURL = post.attributes.details.attachments.media[0].attributes.hostedVersions.suggested.url;
        
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
        imageHeight = imageHeight;
    }
    if (hasImage) {
        height = height + imageHeight;
    }
    
    // 4 on top and 4 on bottom
    BOOL hasLinkPreview = [post hasLinkAttachment];
    if (hasLinkPreview) {
        CGFloat linkPreviewHeight = hasLinkPreview ? [BFLinkAttachmentView heightForLink:post.attributes.details.attachments.link  width:contentWidth-expandedPostContentOffset.left-expandedPostContentOffset.right] : 0; // 8 above
        height = height + linkPreviewHeight + 8; // 8 above
    }
    
    // deatils label
    CGFloat dateHeight = 16 + 30; // 6 + 14 + 12;
    height = height + dateHeight;
    
    // actions
    CGFloat actionsHeight = expandedActionsViewHeight; // 12 = padding above actions view
    height = height + actionsHeight;
    
    return expandedPostContentOffset.top + height + expandedPostContentOffset.bottom; // 1 = line separator
}

@end
