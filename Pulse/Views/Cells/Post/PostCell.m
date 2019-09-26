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
    
    if (self) {
        self.selectable = true;
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.layer.masksToBounds = true;
        self.tintColor = self.superview.tintColor;
        self.contentView.clipsToBounds = true;
        
        self.backgroundColor = [UIColor contentBackgroundColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        
        self.post = [[Post alloc] init];
        
        self.primaryAvatarView = [[BFAvatarView alloc] initWithFrame:CGRectMake(12, 12, 48, 48)];
        self.primaryAvatarView.openOnTap = false;
        self.primaryAvatarView.dimsViewOnTap = true;
        self.primaryAvatarView.allowOnlineDot = true;
        [self.primaryAvatarView bk_whenTapped:^{
            [Launcher openProfile:self.post.attributes.details.creator];
        }];
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
        self.dateLabel.font = [UIFont systemFontOfSize:self.nameLabel.font.pointSize weight:UIFontWeightRegular];
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
        
        #ifdef DEBUG
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
            if (state == UIGestureRecognizerStateBegan) {
                // recognized long press
                [Launcher openDebugView:self.post];
            }
        }];
        [self addGestureRecognizer:longPress];
        #endif
    }
    
    return self;
}

- (void)initImagesView {
    // image view
    self.imagesView = [[PostImagesView alloc] initWithFrame:CGRectMake(self.textView.frame.origin.x, 56, self.textView.frame.size.width, [PostImagesView streamImageHeight])];
    [self.contentView addSubview:self.imagesView];
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
    
    self.linkAttachmentView.link = self.post.attributes.details.attachments.link;
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
    
    self.smartLinkAttachmentView.link = self.post.attributes.details.attachments.link;
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
    
    // TODO: Remove & replace with actual camp
    self.campAttachmentView.camp = self.post.attributes.details.attachments.camp;
}

- (void)removeUserAttachment {
    [self.userAttachmentView removeFromSuperview];
    self.userAttachmentView = nil;
}
- (void)initUserAttachment {
    if (!self.userAttachmentView) {
        // need to initialize a user preview view
        self.userAttachmentView = [[BFUserAttachmentView alloc] init];
        [self.contentView addSubview:self.userAttachmentView];
    }
    
    // TODO: Remove & replace with actual user
    self.userAttachmentView.user = [Session sharedInstance].currentUser; // self.post.attributes.details.attachments.user;
}

+ (NSAttributedString *)attributedCreatorStringForPost:(Post *)post includeTimestamp:(BOOL)includeTimestamp showCamptag:(BOOL)showCamptag {
    UIFont *font = [UIFont systemFontOfSize:15.f weight:UIFontWeightRegular];
    
    if ([post.attributes.status.display.creator isEqualToString:POST_DISPLAY_CREATOR_CAMP] && post.attributes.status.postedIn != nil) {
        // set display name + camp name combo
        NSString *identifier = post.attributes.status.postedIn.attributes.details.title;
        if (post.attributes.status.postedIn.attributes.details.identifier.length > 0) {
            identifier = [@"#" stringByAppendingString:post.attributes.status.postedIn.attributes.details.identifier];
        }
                
        NSMutableAttributedString *camptagString = [[NSMutableAttributedString alloc] initWithString:identifier];
        [camptagString addAttribute:NSForegroundColorAttributeName value:[UIColor bonfirePrimaryColor] range:NSMakeRange(0, camptagString.length)];
        [camptagString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:font.pointSize weight:UIFontWeightSemibold] range:NSMakeRange(0, camptagString.length)];
        
        return camptagString;
    }
    else {
        // set display name + camp name combo
        NSString *username = post.attributes.details.creator.attributes.details.identifier != nil ? [NSString stringWithFormat:@"@%@", post.attributes.details.creator.attributes.details.identifier] : @"anonymous";
        
        NSMutableAttributedString *creatorString = [[NSMutableAttributedString alloc] initWithString:username];
        PatternTapResponder creatorTapResponder = ^(NSString *string) {
            [Launcher openProfile:post.attributes.details.creator];
        };
        [creatorString addAttribute:RLTapResponderAttributeName value:creatorTapResponder range:NSMakeRange(0, creatorString.length)];
        [creatorString addAttribute:NSForegroundColorAttributeName value:[UIColor bonfirePrimaryColor] range:NSMakeRange(0, creatorString.length)];
        
        [creatorString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:font.pointSize weight:UIFontWeightSemibold] range:NSMakeRange(0, creatorString.length)];
        [creatorString addAttribute:RLHighlightedForegroundColorAttributeName value:[[UIColor bonfirePrimaryColor] colorWithAlphaComponent:0.5] range:NSMakeRange(0, creatorString.length)];
        
        /*
         BOOL isVerified = true;
         if (isVerified) {
         NSMutableAttributedString *spacer = [[NSMutableAttributedString alloc] initWithString:@" "];
         [spacer addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, spacer.length)];
         [creatorString appendAttributedString:spacer];
         
         // verified icon ☑️
         NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
         attachment.image = [UIImage imageNamed:@"verifiedIcon_small"];
         [attachment setBounds:CGRectMake(0, roundf(font.capHeight - attachment.image.size.height)/2.f, attachment.image.size.width, attachment.image.size.height)];
         
         NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
         [creatorString appendAttributedString:attachmentString];
         }*/
        
        if (includeTimestamp) {
            NSMutableAttributedString *connector = [[NSMutableAttributedString alloc] initWithString:@"  "];
            [connector addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, connector.length)];
            [creatorString appendAttributedString:connector];
            
            NSString *timeAgo = [NSDate mysqlDatetimeFormattedAsTimeAgo:post.attributes.status.createdAt withForm:TimeAgoShortForm];
            if (timeAgo != nil) {
                NSMutableAttributedString *timeAgoString = [[NSMutableAttributedString alloc] initWithString:timeAgo];
                [timeAgoString addAttribute:NSForegroundColorAttributeName value:[UIColor bonfireSecondaryColor] range:NSMakeRange(0, timeAgoString.length)];
                [timeAgoString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, timeAgoString.length)];
                
                [creatorString appendAttributedString:timeAgoString];
            }
        }
        else if (showCamptag && post.attributes.status.postedIn != 0) {
            // create spacer
            NSMutableAttributedString *spacer = [[NSMutableAttributedString alloc] initWithString:@" "];
            [spacer addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, spacer.length)];
            
            // spacer
            [creatorString appendAttributedString:spacer];
            
            NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
            attachment.image = [UIImage imageNamed:@"postedInTriangleIcon-1"];
            [attachment setBounds:CGRectMake(0, roundf(font.capHeight - attachment.image.size.height)/2.f, attachment.image.size.width, attachment.image.size.height)];
            
            NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
            [creatorString appendAttributedString:attachmentString];
            
            // spacer
            [creatorString appendAttributedString:spacer];
            
            NSString *identifier = post.attributes.status.postedIn.attributes.details.title;
            if (post.attributes.status.postedIn.attributes.details.identifier.length > 0) {
                identifier = [@"#" stringByAppendingString:post.attributes.status.postedIn.attributes.details.identifier];
            }
            
            NSMutableAttributedString *campTitleString = [[NSMutableAttributedString alloc] initWithString:identifier];
            [campTitleString addAttribute:NSForegroundColorAttributeName value:[UIColor bonfirePrimaryColor] range:NSMakeRange(0, campTitleString.length)];
            [campTitleString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:font.pointSize weight:UIFontWeightSemibold] range:NSMakeRange(0, campTitleString.length)];
            
            [creatorString appendAttributedString:campTitleString];
            
            if ([post.attributes.status.postedIn.attributes.status.visibility isPrivate]) {
                // spacer
                [creatorString appendAttributedString:spacer];
                
                NSTextAttachment *lockAttachment = [[NSTextAttachment alloc] init];
                lockAttachment.image = [[UIImage imageNamed:@"inlinePostLockIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                
                [lockAttachment setBounds:CGRectMake(0, roundf(font.capHeight - lockAttachment.image.size.height)/2.f, lockAttachment.image.size.width, lockAttachment.image.size.height)];
                
                NSAttributedString *lockAttachmentString = [NSAttributedString attributedStringWithAttachment:lockAttachment];
                [creatorString appendAttributedString:lockAttachmentString];
            }
        }
        
        return creatorString;
    }
    
    return [NSAttributedString new];
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

@end
