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
#import "LinkConversationsViewController.h"
#import "BFAlertController.h"
#import "BFStreamComponent.h"

#define BFPostContextTextKey @"text"
#define BFPostContextIconKey @"icon"
#define BFPostContextIconColorKey @"icon_color"

#define STREAM_POST_MAX_CHARACTERS 300

@interface StreamPostCell () <BFComponentProtocol>

@end

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
        
        self.clipsToBounds = true;
        
        self.contextView = [[PostContextView alloc] init];
        [self.contextView.highlightView bk_whenTapped:^{
            if (self.post.attributes.parent) {
                [Launcher openPost:self.post.attributes.parent withKeyboard:false];
            }
            else if (self.post.containsMention && ![self.post isCreator]) {
                [Launcher openPost:self.post withKeyboard:false];
            }
        }];
        [self.contentView addSubview:self.contextView];
                
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
        self.imagesView.frame = CGRectMake(self.primaryAvatarView.frame.origin.x, 56, self.frame.size.width - self.primaryAvatarView.frame.origin.x - postContentOffset.right, [PostImagesView streamImageHeight]);
        
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
        [self.actionsView.quoteButton bk_whenTapped:^{
            [Launcher openComposePost:nil inReplyTo:nil withMessage:nil media:nil quotedObject:self.post];
        }];
        [self.actionsView.shareButton bk_whenTapped:^{
            [Launcher sharePost:self.post];
        }];
        [self.contentView addSubview:self.actionsView];
        
        self.lineSeparator.hidden = true;
        
        [self.actionsView.repliesSnaphotView bk_whenTapped:^{
            [Launcher openPost:self.post withKeyboard:false];
        }];
        [self.actionsView.replyButton bk_whenTapped:^{
            [Launcher openComposePost:self.post.attributes.postedIn inReplyTo:self.post withMessage:nil media:nil quotedObject:nil];
        }];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    UIEdgeInsets offset = postContentOffset;
    
    CGFloat yBottom = offset.top;
    
    if (![self.contextView isHidden]) {
        self.contextView.frame = CGRectMake(self.primaryAvatarView.frame.origin.x, postContentOffset.top - 6, self.frame.size.width - (self.primaryAvatarView.frame.origin.x + postContentOffset.right), postContextHeight);
        yBottom = self.contextView.frame.origin.y + self.contextView.frame.size.height + 4;
    }
    
    self.primaryAvatarView.frame = CGRectMake(12, yBottom, self.primaryAvatarView.frame.size.width, self.primaryAvatarView.frame.size.height);
    if (![self.secondaryAvatarView isHidden]) {
        self.secondaryAvatarView.frame = CGRectMake(self.primaryAvatarView.frame.origin.x + self.primaryAvatarView.frame.size.width - self.secondaryAvatarView.frame.size.width, self.primaryAvatarView.frame.origin.y + self.primaryAvatarView.frame.size.height - self.secondaryAvatarView.frame.size.height, self.secondaryAvatarView.frame.size.width, self.secondaryAvatarView.frame.size.height);
    }
    
    if (![self.moreButton isHidden]) {
        CGFloat moreButtonPadding = 14;
        CGFloat moreButtonWidth = self.moreButton.currentImage.size.width + (moreButtonPadding * 2);
        self.moreButton.frame = CGRectMake(self.frame.size.width - moreButtonWidth - postContentOffset.right + moreButtonPadding, yBottom - moreButtonPadding, moreButtonWidth, self.nameLabel.frame.size.height + (moreButtonPadding * 2));
    }
    
    CGSize dateLabelSize = [self.dateLabel.attributedText boundingRectWithSize:CGSizeMake(100, self.actionsView.frame.size.height) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin)  context:nil].size;
    self.dateLabel.frame = CGRectMake(([self.moreButton isHidden] ? self.frame.size.width - offset.right :  self.moreButton.frame.origin.x + 2) - ceilf(dateLabelSize.width), yBottom, ceilf(dateLabelSize.width), self.dateLabel.frame.size.height);
    self.nameLabel.frame = CGRectMake(offset.left, yBottom, (self.dateLabel.frame.origin.x - 8) - offset.left, self.nameLabel.frame.size.height);
    yBottom = self.nameLabel.frame.origin.y + self.nameLabel.frame.size.height;
    
    // -- text view
    if (![self.textView isHidden]) {
        self.textView.frame = CGRectMake(offset.left, yBottom + 3, self.frame.size.width - offset.left - offset.right, self.textView.frame.size.height);
        if (self.post.attributes.simpleMessage.length > 0) {
            self.textView.tintColor = self.tintColor;
            [self.textView update];
            yBottom = self.textView.frame.origin.y + self.textView.frame.size.height;
        }
    }
    
    BOOL hasImage = (self.post.attributes.media.count > 0 || self.post.attributes.attachments.media.count > 0); //self.post.images != nil && self.post.images.count > 0;
    self.imagesView.hidden = !hasImage;
    if (hasImage) {
        CGFloat imageHeight = [PostImagesView streamImageHeight];
        self.imagesView.frame = CGRectMake(offset.left, yBottom + ([self.textView isHidden] ? 5 : 8), self.frame.size.width - offset.left - postContentOffset.right, imageHeight);
        
        [self.imagesView startSpinnersAsNeeded];
        
        yBottom = self.imagesView.frame.origin.y + self.imagesView.frame.size.height;
    }
    
    if (self.videoPlayerAttachmentView) {
        CGFloat videoSize = self.frame.size.width - offset.left - postContentOffset.right;
        
        [self.videoPlayerAttachmentView layoutSubviews];
        self.videoPlayerAttachmentView.frame = CGRectMake(offset.left, yBottom + ([self.textView isHidden] ? 5 : 8), videoSize, videoSize);
        
        yBottom = self.videoPlayerAttachmentView.frame.origin.y + self.videoPlayerAttachmentView.frame.size.height;
    }
    
    if (self.linkAttachmentView) {
        [self.linkAttachmentView layoutSubviews];
        self.linkAttachmentView.frame = CGRectMake(offset.left, yBottom + ([self.textView isHidden] ? 5 : 8), self.frame.size.width - offset.left - postContentOffset.right, [BFLinkAttachmentView heightForLink:self.linkAttachmentView.link width: self.frame.size.width-(postContentOffset.left+postContentOffset.right)]);
        
        yBottom = self.linkAttachmentView.frame.origin.y + self.linkAttachmentView.frame.size.height;
    }
    
    if (self.smartLinkAttachmentView) {
        [self.smartLinkAttachmentView layoutSubviews];
        self.smartLinkAttachmentView.frame = CGRectMake(offset.left, yBottom + ([self.textView isHidden] ? 5 : 8), self.frame.size.width - offset.left - postContentOffset.right, [BFSmartLinkAttachmentView heightForSmartLink:self.smartLinkAttachmentView.link width: self.frame.size.width-(postContentOffset.left+postContentOffset.right) showActionButton:true]);
        
        yBottom = self.smartLinkAttachmentView.frame.origin.y + self.smartLinkAttachmentView.frame.size.height;
    }
    
    if (self.campAttachmentView) {
        [self.campAttachmentView layoutSubviews];
        self.campAttachmentView.frame = CGRectMake(offset.left, yBottom + ([self.textView isHidden] ? 5 : 8), self.frame.size.width - offset.left - postContentOffset.right, [BFCampAttachmentView heightForCamp:self.campAttachmentView.camp width: self.frame.size.width-(postContentOffset.left+postContentOffset.right)]);
        
        yBottom = self.campAttachmentView.frame.origin.y + self.campAttachmentView.frame.size.height;
    }
    
    if (self.identityAttachmentView) {
        [self.identityAttachmentView layoutSubviews];
        self.identityAttachmentView.frame = CGRectMake(offset.left, yBottom + ([self.textView isHidden] ? 5 : 8), self.frame.size.width - offset.left - postContentOffset.right, [BFIdentityAttachmentView heightForIdentity:self.identityAttachmentView.identity width: self.frame.size.width-(postContentOffset.left+postContentOffset.right)]);
        
        yBottom = self.identityAttachmentView.frame.origin.y + self.identityAttachmentView.frame.size.height;
    }
    
    if (self.postAttachmentView) {
        [self.postAttachmentView layoutSubviews];
        self.postAttachmentView.frame = CGRectMake(offset.left, yBottom + ([self.textView isHidden] ? 5 : 8), self.frame.size.width - offset.left - postContentOffset.right, [BFPostAttachmentView heightForPost:self.postAttachmentView.post width: self.frame.size.width-(postContentOffset.left+postContentOffset.right)]);
        
        yBottom = self.postAttachmentView.frame.origin.y + self.postAttachmentView.frame.size.height;
    }
    
    if (self.postRemovedAttachmentView) {
        [self.postRemovedAttachmentView layoutSubviews];
        self.postRemovedAttachmentView.frame = CGRectMake(offset.left, yBottom + ([self.textView isHidden] ? 5 : 8), self.frame.size.width - offset.left - postContentOffset.right, [BFPostDeletedAttachmentView heightForMessage:self.postRemovedAttachmentView.message width: self.frame.size.width-(postContentOffset.left+postContentOffset.right)]);
        
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
    
    BOOL canReply = !_post.attributes.creatorBot && [_post.attributes.context.post.permissions canReply] && self.post.tempId.length == 0;
    BOOL canShare = ![_post.attributes.postedIn isPrivate] && _post.tempId.length == 0;
    BOOL canQuote = canShare;
    
    self.actionsView.userInteractionEnabled = !self.loading && !self.post.tempId;
    self.actionsView.replyButton.userInteractionEnabled = canReply;
    self.actionsView.quoteButton.userInteractionEnabled = canQuote;
    self.actionsView.shareButton.userInteractionEnabled = canShare;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    // support dark mode
    [self drawNameLabel];
}

- (void)setVoted:(BOOL)isVoted animated:(BOOL)animated {
    if (!animated || (isVoted != self.voted)) {
        self.voted = isVoted;
        
        [self.actionsView setVoted:isVoted animated:animated];
        
        void(^rippleAnimation)(void) = ^() {
            if (!self.voted)
                return;
            
            if (self.post.attributes.simpleMessage.length == 0)
                return;
            
            CGFloat bubbleDiamater = (self.frame.size.width > self.frame.size.height ? self.frame.size.width : self.frame.size.height) * 2.2;
            UIView *bubble = [[UIView alloc] initWithFrame:CGRectMake(0, 0, bubbleDiamater, bubbleDiamater)];
            bubble.userInteractionEnabled = false;
            bubble.center = self.textView.center;
            bubble.backgroundColor = [[UIColor fromHex:self.post.themeColor adjustForOptimalContrast:true] colorWithAlphaComponent:0.06];
            bubble.layer.cornerRadius = bubble.frame.size.height / 2;
            bubble.layer.masksToBounds = true;
            bubble.transform = CGAffineTransformMakeScale(0.01, 0.01);
            
            [self.contentView bringSubviewToFront:self.textView];
            [self insertSubview:bubble aboveSubview:self.contentView];
            
            [UIView animateWithDuration:animated?1.3f:0 delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                bubble.transform = CGAffineTransformIdentity;
                bubble.backgroundColor = [[UIColor fromHex:self.post.themeColor] colorWithAlphaComponent:0.12];
            } completion:nil];
            [UIView animateWithDuration:animated?1.3f:0 delay:animated?0.1f:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                bubble.alpha = 0;
            } completion:^(BOOL finished) {
                [bubble removeFromSuperview];
            }];
            
            [UIView animateWithDuration:animated?0.6f:0 delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.contentView.transform = CGAffineTransformMakeScale(0.96, 0.96);
            } completion:nil];
            [UIView animateWithDuration:animated?0.5f:0 delay:animated?0.1f:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.contentView.transform = CGAffineTransformMakeScale(1, 1);
            } completion:nil];
        };
        
        if (animated) {
            rippleAnimation();
        }
    }
}

- (void)drawNameLabel {
    self.nameLabel.attributedText = [PostCell attributedCreatorStringForPost:_post includeTimestamp:false showCamptag:self.showPostedIn primaryColor:nil];
}

+ (BOOL)showDateLabelForPost:(Post *)post {
    if (post.tempId) return true;
    
    if (post.attributes.createdAt.length > 0) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
        NSDate *new = [NSDate date];
        NSCalendar *gregorian = [[NSCalendar alloc]
                                 initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSDateComponents *comps = [gregorian components: NSCalendarUnitDay
                                               fromDate: [formatter dateFromString:post.attributes.createdAt]
                                                 toDate: new
                                                options: 0];
        
        if ([comps day] < 3) {
            return true;
        }
    }
    
    return false;
}

- (void)setPost:(Post *)post {
    if (![post isEqual:_post]) {
        _post = post;
        
        BOOL temporary = _post.tempId;
        
        self.moreButton.tintColor = [UIColor bonfireSecondaryColor];
        self.dateLabel.textColor = [UIColor bonfireSecondaryColor];
        self.contextView.tintColor = [UIColor bonfireSecondaryColor];
        self.actionsView.tintColor = [UIColor fromHex:post.themeColor adjustForOptimalContrast:true];
        
        NSString *date = @"";
        if (_post.tempId) {
            date = @"Posting...";
        }
        else if (_post.attributes.createdAt.length > 0 && [StreamPostCell showDateLabelForPost:self.post]) {
            date = [NSDate mysqlDatetimeFormattedAsTimeAgo:_post.attributes.createdAt withForm:TimeAgoShortForm];
        }
        else {
            date = @"";
        }
        self.dateLabel.text = date;
        self.dateLabel.hidden = date.length == 0;
        
        [self drawNameLabel];
        
        BOOL canReply = !_post.attributes.creatorBot && [_post.attributes.context.post.permissions canReply] && self.post.tempId.length == 0;
        BOOL canShare = ![_post.attributes.postedIn isPrivate] && _post.tempId.length == 0;
        BOOL canQuote = canShare;
        
        self.userInteractionEnabled = !(temporary);
        self.actionsView.replyButton.alpha = !temporary && canReply ? 1 : 0.25;
        self.actionsView.quoteButton.alpha = !temporary && canQuote ? 1 : 0.25;
        self.actionsView.shareButton.alpha = !temporary && canShare ? 1 : 0.25;
        self.actionsView.voteButton.alpha = temporary ? 0.25 : 1;
                
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
        
        self.secondaryAvatarView.hidden = !self.showPostedIn || !(!self.primaryAvatarView.camp && post.attributes.postedIn != nil && self.showPostedIn);
        if (![self.secondaryAvatarView isHidden]) {
            self.secondaryAvatarView.camp = post.attributes.postedIn;
        }
                
        BOOL removed = [self.post isRemoved];
        
        self.actionsView.hidden = removed || _hideActions;
        if (![self.actionsView isHidden]) {
            self.actionsView.alpha = 1;
            self.actionsView.userInteractionEnabled = !self.hideActions;
            
            [self.actionsView setSummaries:self.post.attributes.summaries];
        }
        
        self.moreButton.hidden = temporary || removed || self.hideActions;
        self.contextView.hidden = removed;
        if (removed) {
            [self.textView setMessage:@"" entities:nil];
            
            if (!self.postRemovedAttachmentView) {
                [self initPostRemovedAttachment];
            }
            // remove unnceeded attachment views, if needed
            if (self.linkAttachmentView) {
                [self removeLinkAttachment];
            }
            if (self.videoPlayerAttachmentView) {
                [self removeVideoPlayerAttachmentView];
            }
            if (self.smartLinkAttachmentView) {
                [self removeSmartLinkAttachment];
            }
            if (self.campAttachmentView) {
                [self removeCampAttachment];
            }
            if (self.identityAttachmentView) {
                [self removeIdentityAttachment];
            }
            if (self.postAttachmentView) {
                [self removePostAttachment];
            }
        }
        else {
            NSDictionary *context = (self.showContext ? [StreamPostCell contextForPost:post] : nil);
            self.contextView.hidden = !context;
            if (context) {
                self.contextView.attributedText = context[BFPostContextTextKey];
                self.contextView.icon = context[BFPostContextIconKey];
            }
            
            BOOL hasMessage = (self.post.attributes.simpleMessage.length > 0);
                      
            if (self.post.attributes.attachments.media.count > 0) {
                [self.imagesView setMedia:self.post.attributes.attachments.media];
            }
            else if (self.post.attributes.media.count > 0) {
                [self.imagesView setMedia:self.post.attributes.media];
            }
            else {
                [self.imagesView setMedia:@[]];
            }
            
            if (hasMessage) {
                UIFont *font = [post isEmojiPost] ? [UIFont systemFontOfSize:ceilf(textViewFont.pointSize*POST_EMOJI_SIZE_MULTIPLIER)] : textViewFont;
                self.textView.messageLabel.font = font;
                self.textView.postId = self.post.identifier;
                
                if (self.imagesView.media.count > 0 && [PostImagesView useCaptionedImageViewForPost:self.post]) {
                    [self.textView setMessage:@"" entities:nil];
                    self.imagesView.caption = self.post.attributes.simpleMessage;
                    self.imagesView.captionTextView.backgroundColor = [UIColor fromHex:self.post.themeColor];
                    self.imagesView.captionTextView.textColor = [UIColor highContrastForegroundForBackground:self.imagesView.captionTextView.backgroundColor];
                }
                else {
                    [self.textView setMessage:self.post.attributes.simpleMessage entities:self.post.attributes.entities];
                    self.imagesView.caption = @"";
                }
            }
            else {
                [self.textView setMessage:@"" entities:nil];
                self.imagesView.caption = @"";
            }
            self.textView.hidden = (removed || self.textView.message.length == 0 || self.imagesView.caption.length > 0);
            
            // removed post removed attachment
            if (self.postRemovedAttachmentView) {
                [self removePostRemovedAttachment];
            }
            
            // video attachment
            if ([self.post hasVideoAttachment]) {
                [self initVideoPlayerAttachmentView];
                self.videoPlayerAttachmentView.videoURL = self.post.attributes.attachments.video.attributes.hostedVersions.suggested.url;
            }
            else if (self.videoPlayerAttachmentView) {
                [self removeVideoPlayerAttachmentView];
            }
            
            // smart link attachment
            if ([self.post hasLinkAttachment]) {
                if ([self.post.attributes.attachments.link isSmartLink]) {
                    if (self.minimizeLinks) {
                        [self initPostRemovedAttachment];
                        self.postRemovedAttachmentView.message = @"↑ Quoting this link";
                        [self removeSmartLinkAttachment];
                        [self removeLinkAttachment];
                    }
                    else {
                        [self initSmartLinkAttachment];
                        self.smartLinkAttachmentView.shareLinkButton.hidden = self.hideActions;
                        [self removeLinkAttachment];
                    }
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
                [self initIdentityAttachment];
            }
            else if (self.identityAttachmentView) {
                [self removeIdentityAttachment];
            }
            
            // post attachment
            if ([self.post hasPostAttachment]) {
                [self initPostAttachment];
            }
            else if (self.postAttachmentView) {
                [self removePostAttachment];
            }
            
            if (![self.actionsView isHidden]) {
                self.actionsView.actionsType = PostActionsViewTypeConversation;
                
                [self.actionsView.replyButton setTitle:@"Reply" forState:UIControlStateNormal];
            }
        }
    }
    
    [self setVoted:(self.post.attributes.context.post.vote != nil) animated:false];
}
- (UIImage *)colorImage:(UIImage *)image color:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(image.size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextTranslateCTM(context, 0, image.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);

    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGContextDrawImage(context, rect, image.CGImage);
    CGContextSetBlendMode(context, kCGBlendModeSourceIn);
    [color setFill];
    CGContextFillRect(context, rect);


    UIImage *coloredImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return coloredImage;
}

+ (CGFloat)heightForPost:(Post *)post showContext:(BOOL)showContext showActions:(BOOL)showActions minimizeLinks:(BOOL)minimizeLinks {
    CGFloat height = postContentOffset.top;
    
    if ([post isRemoved]) {
        // force hidden actions if the post has been removed
        showActions = false;
    }
    
    BOOL hasContext = (showContext && [self contextForPost:post]);
    if (hasContext) {
        height += postContextHeight - 2;
     }
    
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    
    CGFloat nameHeight = 18; // 3pt padding underneath
    height += nameHeight;
    
    BOOL hasMessage = (post.attributes.simpleMessage.length > 0 && ![PostImagesView useCaptionedImageViewForPost:post]);
    if (hasMessage) {
        // message
        UIFont *font = [post isEmojiPost] ? [UIFont systemFontOfSize:ceilf(textViewFont.pointSize*POST_EMOJI_SIZE_MULTIPLIER)] : textViewFont;
        
        CGFloat messageHeight = [PostTextView sizeOfBubbleWithMessage:post.attributes.simpleMessage withConstraints:CGSizeMake(screenWidth - postContentOffset.left - postContentOffset.right, CGFLOAT_MAX) font:font maxCharacters:[PostTextView entityBasedMaxCharactersForMessage:post.attributes.simpleMessage maxCharacters:STREAM_POST_MAX_CHARACTERS entities:post.attributes.entities] styleAsBubble:false].height;
        
        CGFloat textViewHeight = ceilf(messageHeight) + 3; // 3 on top
        height = height + textViewHeight;
    }
    
    // image
    BOOL hasImage = post.attributes.media.count > 0 || post.attributes.attachments.media.count > 0; // postAtIndex.images != nil && postAtIndex.images.count > 0;
    if (hasImage) {
        CGFloat imageHeight = [PostImagesView streamImageHeight];
        imageHeight = imageHeight + (hasMessage ? 8 : 5); // 8 above
        height = height + imageHeight;
    }
    
    if ([post hasVideoAttachment]) {
        CGFloat videoPlayerAttachmentHeight = screenWidth-postContentOffset.left-postContentOffset.right;
        height += videoPlayerAttachmentHeight + (hasMessage ? 8 : 5); // 8 above
    }
    
    if ([post hasLinkAttachment]) {
        CGFloat linkPreviewHeight;
        if ([post.attributes.attachments.link isSmartLink]) {
            if (minimizeLinks) {
                NSString *message = @"↑ Quoting this link";
                linkPreviewHeight = [BFPostDeletedAttachmentView heightForMessage:message width:screenWidth-postContentOffset.left-postContentOffset.right];
            }
            else {
                linkPreviewHeight = [BFSmartLinkAttachmentView heightForSmartLink:post.attributes.attachments.link  width:screenWidth-postContentOffset.left-postContentOffset.right showActionButton:showActions];
            }
        }
        else {
            linkPreviewHeight = [BFLinkAttachmentView heightForLink:post.attributes.attachments.link  width:screenWidth-postContentOffset.left-postContentOffset.right];
        }

        height += linkPreviewHeight + (hasMessage ? 8 : 5); // 8 above
    }
    
    if ([post hasCampAttachment]) {
        Camp *camp = post.attributes.attachments.camp;
        
        CGFloat campAttachmentHeight = [BFCampAttachmentView heightForCamp:camp width:screenWidth-postContentOffset.left-postContentOffset.right];
        height = height + campAttachmentHeight + (hasMessage ? 8 : 5); // 8 above
    }
    
    if ([post hasUserAttachment]) {
        User *user = post.attributes.attachments.user;
        
        CGFloat userAttachmentHeight = [BFIdentityAttachmentView heightForIdentity:user width:screenWidth-postContentOffset.left-postContentOffset.right];
        height = height + userAttachmentHeight + (hasMessage ? 8 : 5); // 8 above
    }
    
    if ([post hasPostAttachment]) {
        Post *quotedPost = post.attributes.attachments.post;
        
        CGFloat postAttachmentHeight = [BFPostAttachmentView heightForPost:quotedPost width:screenWidth-postContentOffset.left-postContentOffset.right];
        height += postAttachmentHeight + (hasMessage ? 8 : 5); // 8 above
    }
    
    if ([post isRemoved]) {
        NSString *message = post.attributes.removedReason;
        
        CGFloat postRemovedAttachmentHeight = [BFPostDeletedAttachmentView heightForMessage:message width:screenWidth-postContentOffset.left-postContentOffset.right];
        height += postRemovedAttachmentHeight + (hasMessage ? 8 : 5); // 3 above (remember, there's no content if the post has been removed)
    }
    
    if ([post isRemoved] || !showActions) {
        height += 16;
    }
    else {
        CGFloat detailsHeight = 8 + POST_ACTIONS_VIEW_HEIGHT;
        height += detailsHeight + postContentOffset.bottom;
    }
    
    CGFloat minHeight = postContentOffset.top + (hasContext ? postContextHeight - 2 : 0) + 42 + postContentOffset.bottom;
    
    return MAX(minHeight, height);
}

+ (NSDictionary *)contextForPost:(Post *)post {
    NSMutableAttributedString *attributedText;
    UIImage *icon;
    
    UIFont *font = [UIFont systemFontOfSize:15.f weight:UIFontWeightRegular];
    NSAttributedString *attributedCreatorText;
    
    NSString *parentUsername;
    if (post.attributes.parent.attributes.creator.attributes.identifier)  {
        parentUsername = post.attributes.parent.attributes.creator.attributes.identifier;
    }
    else if (post.attributes.parentCreatorUsername) {
        parentUsername = post.attributes.parentCreatorUsername;
    }
    
    if (post.attributes.pinned) {
        attributedText = [[NSMutableAttributedString alloc] initWithString:@"Pinned Post" attributes:@{NSFontAttributeName: font, NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor]}];
        
        icon = [[UIImage imageNamed:@"notificationIndicator_pin"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    else if (parentUsername) {
        attributedText = [[NSMutableAttributedString alloc] initWithString:@"Replying to " attributes:@{NSFontAttributeName: font, NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor]}];
        
        if ([parentUsername isEqualToString:[Session sharedInstance].currentUser.attributes.identifier]) {
            attributedCreatorText = [[NSAttributedString alloc] initWithString:@"you" attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:font.pointSize weight:UIFontWeightSemibold], NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor]}];
        }
        else {
            attributedCreatorText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"@%@", parentUsername] attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:15.f weight:UIFontWeightSemibold], NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor]}];
        }
        [attributedText appendAttributedString:attributedCreatorText];
        
        icon = [[UIImage imageNamed:@"notificationIndicator_reply"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    else if (post.containsMention && ![post isCreator]) {
        NSString *creatorUsername = post.attributes.creator.attributes.identifier;
        
        attributedText = [[NSMutableAttributedString alloc] initWithString:@"You were mentioned by " attributes:@{NSFontAttributeName: font, NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor]}];
        
        attributedCreatorText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"@%@", creatorUsername] attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:15.f weight:UIFontWeightBold], NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor]}];
        [attributedText appendAttributedString:attributedCreatorText];
        
        icon = [[UIImage imageNamed:@"notificationIndicator_mention"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    
    if (attributedText.length > 0 && icon) {
        return @{BFPostContextTextKey: attributedText, BFPostContextIconKey: icon};
    }
    
    return nil;
}

+ (CGFloat)heightForComponent:(BFStreamComponent *)component {
    Post *post = component.post;
    
    if (!post) return 0;
    
    BOOL showContext = component.detailLevel == BFComponentDetailLevelAll;
    BOOL hideActions = component.detailLevel == BFComponentDetailLevelMinimum;
    
    return [StreamPostCell heightForPost:post showContext:showContext showActions:!hideActions minimizeLinks:false];
}

@end
