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
#import "ComplexNavigationController.h"
#import "Launcher.h"
#import "UIColor+Palette.h"
#import <JGProgressHUD/JGProgressHUD.h>

#define UIViewParentController(__view) ({ \
    UIResponder *__responder = __view; \
    while ([__responder isKindOfClass:[UIView class]]) \
    __responder = [__responder nextResponder]; \
    (UIViewController *)__responder; \
    })

@implementation PostCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    self.contentView.backgroundColor = [UIColor contentBackgroundColor];
    if (self) {
        self.selectable = true;
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.layer.masksToBounds = true;
        self.tintColor = self.superview.tintColor;
        self.contentView.clipsToBounds = true;
        
        self.backgroundColor = [UIColor contentBackgroundColor];
        self.contentView.backgroundColor = [UIColor contentBackgroundColor];
        
        self.post = [[Post alloc] init];
        
        self.primaryAvatarView = [[BFAvatarView alloc] initWithFrame:CGRectMake(12, 12, 48, 48)];
        self.primaryAvatarView.openOnTap = true;
        self.primaryAvatarView.allowOnlineDot = true;
        [self.contentView addSubview:self.primaryAvatarView];
        
        self.secondaryAvatarView = [[BFAvatarView alloc] initWithFrame:CGRectMake(self.primaryAvatarView.frame.size.width - 20, self.primaryAvatarView.frame.size.height - 20, 20, 20)];
        self.secondaryAvatarView.openOnTap = true;
        self.secondaryAvatarView.dimsViewOnTap = true;
        UIView *whiteOutline = [[UIView alloc] initWithFrame:CGRectMake(-2, -2, self.secondaryAvatarView.frame.size.width + 4, self.secondaryAvatarView.frame.size.height + 4)];
        whiteOutline.backgroundColor = [UIColor contentBackgroundColor];
        whiteOutline.layer.cornerRadius = whiteOutline.frame.size.width / 2;
        [self.secondaryAvatarView insertSubview:whiteOutline atIndex:0];
        self.secondaryAvatarView.hidden = true;
        [self.contentView addSubview:self.secondaryAvatarView];
        
        self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 12, self.contentView.frame.size.width - 12 - 12, 15)];
        self.nameLabel.text = @"Display Name";
        self.nameLabel.numberOfLines = 1;
        self.nameLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        self.nameLabel.userInteractionEnabled = YES;
        self.nameLabel.textColor = [UIColor bonfirePrimaryColor];
        [self.contentView addSubview:self.nameLabel];
        
        self.dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.nameLabel.frame.origin.y, 21, self.nameLabel.frame.size.height)];
        self.dateLabel.font = [UIFont systemFontOfSize:15.f weight:UIFontWeightRegular];
        self.dateLabel.textAlignment = NSTextAlignmentRight;
        self.dateLabel.textColor = [UIColor bonfireSecondaryColor];
        [self.contentView addSubview:self.dateLabel];
        
        self.moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.moreButton.contentMode = UIViewContentModeCenter;
        [self.moreButton setImage:[UIImage imageNamed:@"postActionMore"] forState:UIControlStateNormal];
        self.moreButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0);
        self.moreButton.frame = CGRectMake(0, self.dateLabel.frame.origin.y, self.moreButton.currentImage.size.width, self.dateLabel.frame.size.height);
        self.moreButton.adjustsImageWhenHighlighted = false;
        [self.moreButton bk_whenTapped:^{
            [Launcher openActionsForPost:self.post];
        }];
        [self.contentView addSubview:self.moreButton];
        
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 58, self.contentView.frame.size.width - (12 * 2), 200)];
        self.titleLabel.textColor = [UIColor bonfirePrimaryColor];
        self.titleLabel.font = [UIFont poppinsBoldFontOfSize:24.f];
        self.titleLabel.hidden = true;
        self.titleLabel.numberOfLines = 0;
        self.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [self.contentView addSubview:self.titleLabel];
        
        // text view
        self.textView = [[PostTextView alloc] initWithFrame:CGRectMake(12, 58, self.contentView.frame.size.width - (12 + 12), 200)]; // 58 will change based on whether or not the detail label is shown
        self.textView.messageLabel.font = textViewFont;
        self.textView.delegate = self;
        self.textView.tintColor = self.tintColor;
        [self.contentView addSubview:self.textView];
        
        [self initImagesView];
        
        self.lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, (1 / [UIScreen mainScreen].scale))];
        self.lineSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
        [self addSubview:self.lineSeparator];
        
        self.topLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 3, 0)];
        self.topLine.backgroundColor = [UIColor threadLineColor];
        self.topLine.layer.cornerRadius = self.topLine.frame.size.width / 2;
        self.topLine.hidden = true;
        [self.contentView addSubview:self.topLine];
        
        self.bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 3, 0)];
        self.bottomLine.backgroundColor = [UIColor threadLineColor];
        self.bottomLine.layer.cornerRadius = self.bottomLine.frame.size.width / 2;
        self.bottomLine.hidden = true;
        [self.contentView addSubview:self.bottomLine];
    }
    
    return self;
}

- (void)initImagesView {
    // image view
    self.imagesView = [[PostImagesView alloc] initWithFrame:CGRectMake(self.textView.frame.origin.x, 56, self.textView.frame.size.width, [PostImagesView streamImageHeight])];
    [self.contentView insertSubview:self.imagesView belowSubview:self.primaryAvatarView];
}

- (void)removeLinkAttachment {
    [self.linkAttachmentView removeFromSuperview];
    self.linkAttachmentView = nil;
}
- (void)initLinkAttachment {
    if (!self.linkAttachmentView) {
        // need to initialize a user preview view
        self.linkAttachmentView = [[BFLinkAttachmentView alloc] init];        
        [self.contentView addSubview:self.linkAttachmentView];
    }
    
    self.linkAttachmentView.link = self.post.attributes.attachments.link;
}

- (void)removeSmartLinkAttachment {
    [self.smartLinkAttachmentView removeFromSuperview];
    self.smartLinkAttachmentView = nil;
}
- (void)initSmartLinkAttachment {
    if (!self.smartLinkAttachmentView) {
        // need to initialize a user preview view
        self.smartLinkAttachmentView = [[BFSmartLinkAttachmentView alloc] init];
        [self.contentView addSubview:self.smartLinkAttachmentView];
    }
    
    self.smartLinkAttachmentView.link = self.post.attributes.attachments.link;
}

- (void)removeCampAttachment {
    [self.campAttachmentView removeFromSuperview];
    self.campAttachmentView = nil;
}
- (void)initCampAttachment {
    if (!self.campAttachmentView) {
        // need to initialize a user preview view
        self.campAttachmentView = [[BFCampAttachmentView alloc] init];
        [self.contentView addSubview:self.campAttachmentView];
    }
    
    self.campAttachmentView.camp = self.post.attributes.attachments.camp;
}

- (void)removeIdentityAttachment {
    [self.identityAttachmentView removeFromSuperview];
    self.identityAttachmentView = nil;
}
- (void)initIdentityAttachment {
    if (!self.identityAttachmentView) {
        // need to initialize a user preview view
        self.identityAttachmentView = [[BFIdentityAttachmentView alloc] init];
        [self.contentView addSubview:self.identityAttachmentView];
    }
    
    self.identityAttachmentView.identity = self.post.attributes.attachments.user;
}

- (void)removePostRemovedAttachment {
    [self.postRemovedAttachmentView removeFromSuperview];
    self.postRemovedAttachmentView = nil;
}
- (void)initPostRemovedAttachment {
    if (!self.postRemovedAttachmentView) {
        // need to initialize a user preview view
        self.postRemovedAttachmentView = [[BFPostDeletedAttachmentView alloc] init];
        [self.contentView addSubview:self.postRemovedAttachmentView];
    }
    
    self.postRemovedAttachmentView.message = self.post.attributes.removedReason;
}

- (void)removePostAttachment {
    [self.postAttachmentView removeFromSuperview];
    self.postAttachmentView = nil;
}
- (void)initPostAttachment {
    if (!self.postAttachmentView) {
        // need to initialize a user preview view
        self.postAttachmentView = [[BFPostAttachmentView alloc] init];
        [self.contentView addSubview:self.postAttachmentView];
    }
    
    self.postAttachmentView.post = self.post.attributes.attachments.post;
}

+ (NSAttributedString *)attributedCreatorStringForPost:(Post *)post includeTimestamp:(BOOL)includeTimestamp showCamptag:(BOOL)showCamptag primaryColor:(UIColor * _Nullable)primaryColor {
    UIFont *font = [UIFont systemFontOfSize:15.f weight:UIFontWeightRegular];
    
    UIColor *secondaryColor = [UIColor bonfireSecondaryColor];
    if (primaryColor) {
        secondaryColor = [primaryColor colorWithAlphaComponent:0.5];
    }
    else {
        primaryColor = [UIColor bonfirePrimaryColor];
    }
    
    BOOL showUsername = !([post.attributes.display.creator isEqualToString:POST_DISPLAY_CREATOR_CAMP] && post.attributes.postedIn != nil);
    if (!showUsername && !showCamptag) {
        showCamptag = true;
    }
    
    NSMutableAttributedString *creatorString = [[NSMutableAttributedString alloc] init];
    if (showUsername) {
        // set display name + camp name combo
        NSString *username = post.attributes.creator.attributes.identifier != nil ? [NSString stringWithFormat:@"@%@", post.attributes.creator.attributes.identifier] : @"anonymous";
        
        [creatorString appendAttributedString:[[NSAttributedString alloc] initWithString:username]];
        [creatorString addAttribute:NSForegroundColorAttributeName value:primaryColor range:NSMakeRange(0, creatorString.length)];
        
        [creatorString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:font.pointSize weight:UIFontWeightSemibold] range:NSMakeRange(0, creatorString.length)];
        [creatorString addAttribute:RLHighlightedForegroundColorAttributeName value:[primaryColor colorWithAlphaComponent:0.5] range:NSMakeRange(0, creatorString.length)];
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *comps;
    if (post.attributes.createdAt.length > 0) {
        comps = [gregorian components: NSCalendarUnitDay
                             fromDate: [formatter dateFromString:post.attributes.createdAt]
                               toDate: [NSDate date]
                              options: 0];
    }
    if (includeTimestamp && comps && [comps day] < 1) {
        NSMutableAttributedString *connector = [[NSMutableAttributedString alloc] initWithString:@"  "];
        [connector addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, connector.length)];
        [creatorString appendAttributedString:connector];
        
        NSString *timeAgo = [NSDate mysqlDatetimeFormattedAsTimeAgo:post.attributes.createdAt withForm:TimeAgoShortForm];
        if (timeAgo != nil) {
            NSMutableAttributedString *timeAgoString = [[NSMutableAttributedString alloc] initWithString:timeAgo];
            [timeAgoString addAttribute:NSForegroundColorAttributeName value:secondaryColor range:NSMakeRange(0, timeAgoString.length)];
            [timeAgoString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:font.pointSize-2.f weight:UIFontWeightMedium] range:NSMakeRange(0, timeAgoString.length)];
            
            [creatorString appendAttributedString:timeAgoString];
        }
    }
    
    if (showCamptag && post.attributes.postedIn != 0) {
        // create spacer
        NSMutableAttributedString *spacer = [[NSMutableAttributedString alloc] initWithString:@" "];
        [spacer addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, spacer.length)];
        
        if (showUsername) {
            // spacer
            [creatorString appendAttributedString:spacer];
            
            NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
            attachment.image = [UIImage imageNamed:@"postedInTriangleIcon"];
            [attachment setBounds:CGRectMake(0, roundf(font.capHeight - attachment.image.size.height)/2.f, attachment.image.size.width, attachment.image.size.height)];
            
            NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
            [creatorString appendAttributedString:attachmentString];
            
            // spacer
            [creatorString appendAttributedString:spacer];
        }
        
        NSString *identifier = post.attributes.postedIn.attributes.title;
        if (post.attributes.postedIn.attributes.identifier.length > 0) {
            identifier = [@"#" stringByAppendingString:post.attributes.postedIn.attributes.identifier];
        }
        
        NSMutableAttributedString *campTitleString = [[NSMutableAttributedString alloc] initWithString:identifier];
        [campTitleString addAttribute:NSForegroundColorAttributeName value:primaryColor range:NSMakeRange(0, campTitleString.length)];
        [campTitleString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:font.pointSize weight:UIFontWeightSemibold] range:NSMakeRange(0, campTitleString.length)];
        
        [creatorString appendAttributedString:campTitleString];
        
        if ([post.attributes.postedIn isPrivate]) {
            // spacer
            [creatorString appendAttributedString:spacer];
            
            NSTextAttachment *lockAttachment = [[NSTextAttachment alloc] init];
            lockAttachment.image = [self colorImage:[UIImage imageNamed:@"details_label_private"] color:[UIColor bonfirePrimaryColor]];
            
            CGFloat attachmentHeight = MIN(ceilf(font.lineHeight * 0.7), lockAttachment.image.size.height);
            CGFloat attachmentWidth = attachmentHeight * (lockAttachment.image.size.width / lockAttachment.image.size.height);
            
            [lockAttachment setBounds:CGRectMake(0, roundf(font.capHeight - attachmentHeight)/2.f, attachmentWidth, attachmentHeight)];
                        
            NSAttributedString *lockAttachmentString = [NSAttributedString attributedStringWithAttachment:lockAttachment];
            [creatorString appendAttributedString:lockAttachmentString];
        }
        else if ([post.attributes.postedIn isChannel]) {
            // spacer
            [creatorString appendAttributedString:spacer];
            
            NSTextAttachment *sourceAttachment = [[NSTextAttachment alloc] init];
            sourceAttachment.image = [self colorImage:[UIImage imageNamed:@"details_label_source"] color:[UIColor bonfirePrimaryColor]];
            
            CGFloat attachmentHeight = MIN(ceilf(font.lineHeight * 0.7), sourceAttachment.image.size.height);
            CGFloat attachmentWidth = attachmentHeight * (sourceAttachment.image.size.width / sourceAttachment.image.size.height);
            
            [sourceAttachment setBounds:CGRectMake(0, roundf(font.capHeight - attachmentHeight)/2.f, attachmentWidth, attachmentHeight)];
            
            NSAttributedString *lockAttachmentString = [NSAttributedString attributedStringWithAttachment:sourceAttachment];
            [creatorString appendAttributedString:lockAttachmentString];
        }
        else if ([post.attributes.postedIn isFeed]) {
            // spacer
            [creatorString appendAttributedString:spacer];
            
            NSTextAttachment *sourceAttachment = [[NSTextAttachment alloc] init];
            sourceAttachment.image = [self colorImage:[UIImage imageNamed:@"details_label_feed"] color:[UIColor bonfirePrimaryColor]];
            
            CGFloat attachmentHeight = MIN(ceilf(font.lineHeight * 0.7), sourceAttachment.image.size.height);
            CGFloat attachmentWidth = attachmentHeight * (sourceAttachment.image.size.width / sourceAttachment.image.size.height);
            
            [sourceAttachment setBounds:CGRectMake(0, roundf(font.capHeight - attachmentHeight)/2.f, attachmentWidth, attachmentHeight)];
            
            NSAttributedString *lockAttachmentString = [NSAttributedString attributedStringWithAttachment:sourceAttachment];
            [creatorString appendAttributedString:lockAttachmentString];
        }
    }
    
    return creatorString;
}

+ (UIImage *)colorImage:(UIImage *)image color:(UIColor *)color
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

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    
    if (!self.selectable) return;
    
    if (self.post && highlighted) {
        [UIView animateWithDuration:0.15f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            if (!self.unread) {
                self.contentView.backgroundColor = [UIColor contentHighlightedColor];
            }
            else {
                self.contentView.backgroundColor = [UIColor colorNamed:@"NewBackgroundColor_Highlighted"];
            }
        } completion:nil];
    }
    else {
        [UIView animateWithDuration:0.15f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            if (!self.unread) {
                self.contentView.backgroundColor = [UIColor contentBackgroundColor];
            }
            else {
                self.contentView.backgroundColor = [UIColor colorNamed:@"NewBackgroundColor"];
            }
        } completion:nil];
    }
}

@end
