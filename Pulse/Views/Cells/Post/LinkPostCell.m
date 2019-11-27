//
//  LinkPostCell.m
//  Hallway App
//
//  Created by Austin Valleskey on 3/10/18.
//  Copyright © 2018 Ingenious, Inc. All rights reserved.
//

#import "LinkPostCell.h"
#import <BlocksKit/BlocksKit+UIKit.h>
#import <SafariServices/SafariServices.h>
#import "NSDate+NVTimeAgo.h"
#import <HapticHelper/HapticHelper.h>
#import "Session.h"
#import "Launcher.h"
#import "UIColor+Palette.h"
#import <SDWebImage/SDImageCache.h>
#import <SDWebImage/UIImageView+WebCache.h>

#define SAMPLE_TITLE_STRING @"The Fed cut rates for the second time this year"
#define SAMPLE_SUMMARY_STRING @"Washington (CNN Business) The Federal Reserve on Wednesday cut interest rates for the second time since July as concerns grow about a potential global slowdown."

@implementation LinkPostCell

@synthesize link = _link;

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor contentBackgroundColor];
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.link = [[BFLink alloc] init];
        
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenRect.size.width;
        
        self.contentView.frame = CGRectMake(0, 0, screenWidth, 100);
        self.contentView.layer.masksToBounds = false;
                
        // image view
        self.imagePreviewView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 160)];
        self.imagePreviewView.backgroundColor = [UIColor bonfireSecondaryColor];
        self.imagePreviewView.contentMode = UIViewContentModeScaleAspectFill;
        self.imagePreviewView.clipsToBounds = true;
        //[self.contentView addSubview:self.imagePreviewView];
        
        self.postedInButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.postedInButton.frame = CGRectMake(expandedLinkContentOffset.left, 160 - 18, 122, 36);
        self.postedInButton.layer.cornerRadius = self.postedInButton.frame.size.height / 2;
        self.postedInButton.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.postedInButton.backgroundColor = [UIColor cardBackgroundColor];
        self.postedInButton.layer.shadowOffset = CGSizeMake(0, 1);
        self.postedInButton.layer.shadowColor = [UIColor blackColor].CGColor;
        self.postedInButton.layer.shadowRadius = 2.f;
        self.postedInButton.layer.shadowOpacity = 0.12f;
        [self.postedInButton setTitleColor:[UIColor bonfirePrimaryColor] forState:UIControlStateNormal];
        self.postedInButton.titleLabel.font = [UIFont systemFontOfSize:15.f weight:UIFontWeightBold];
        self.postedInButton.contentEdgeInsets = UIEdgeInsetsMake(0, 34, 0, 12);
        self.postedInButton.hidden = false;
        [self.postedInButton bk_whenTapped:^{
            if (self.link.attributes.attribution != nil) {
                [Launcher openCamp:self.link.attributes.attribution];
            }
        }];
        [self.postedInButton bk_addEventHandler:^(id sender) {
            [UIView animateWithDuration:0.6f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
                self.postedInButton.transform = CGAffineTransformMakeScale(0.96, 0.96);
            } completion:nil];
        } forControlEvents:UIControlEventTouchDown];
        [self.postedInButton bk_addEventHandler:^(id sender) {
            [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
                self.postedInButton.transform = CGAffineTransformIdentity;
            } completion:nil];
        } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
        
        BFAvatarView *postedInAvatarView = [[BFAvatarView alloc] initWithFrame:CGRectMake(5, 5, self.postedInButton.frame.size.height - 10, self.postedInButton.frame.size.height - 10)];
        postedInAvatarView.userInteractionEnabled = false;
        postedInAvatarView.dimsViewOnTap = false;
        postedInAvatarView.tag = 10;
        [self.postedInButton addSubview:postedInAvatarView];
        
        [self.contentView addSubview:self.postedInButton];
        
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 58, self.contentView.frame.size.width - (12 * 2), 200)];
        self.titleLabel.textColor = [UIColor bonfirePrimaryColor];
        self.titleLabel.font = expandedLinkTitleLabelFont;
        self.titleLabel.hidden = true;
        self.titleLabel.numberOfLines = 0;
        self.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [self.contentView addSubview:self.titleLabel];
        
        self.summaryLabel = [[UILabel alloc] initWithFrame:CGRectMake(expandedLinkContentOffset.left, self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + 12, [UIScreen mainScreen].bounds.size.width - expandedLinkContentOffset.right - expandedLinkContentOffset.left, 200)];
        self.summaryLabel.font = expandedLinkTextViewFont;
        self.summaryLabel.textColor = [UIColor bonfirePrimaryColor];
        self.summaryLabel.numberOfLines = 0;
        self.summaryLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [self.contentView addSubview:self.summaryLabel];
        
        self.activityView = [[PostActivityView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - 30, self.frame.size.width, 30)];
        [self.contentView addSubview:self.activityView];
        
        self.linkURLLabel = [[UILabel alloc] initWithFrame:CGRectMake(expandedLinkContentOffset.left, self.summaryLabel.frame.origin.y + self.summaryLabel.frame.size.height + 8, self.frame.size.width - (expandedLinkContentOffset.left + expandedLinkContentOffset.right), 16)];
        self.linkURLLabel.font = [UIFont systemFontOfSize:14.f];
        [self.contentView addSubview:self.linkURLLabel];
        
        self.activityLineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, (1 / [UIScreen mainScreen].scale))];
        self.activityLineSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
        [self.contentView addSubview:self.activityLineSeparator];
        
        self.lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, (1 / [UIScreen mainScreen].scale))];
        self.lineSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
        [self.contentView addSubview:self.lineSeparator];
    }
    
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    CGPoint translatedPoint = [_postedInButton convertPoint:point fromView:self];

    if (CGRectContainsPoint(_postedInButton.bounds, translatedPoint)) {
        return [_postedInButton hitTest:translatedPoint withEvent:event];
    }
    
    return [super hitTest:point withEvent:event];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
        
    self.contentView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    
    CGFloat yBottom = 0;
    
    if (![self.postedInButton isHidden]) {
        CGFloat postedInButtonWidth = self.postedInButton.intrinsicContentSize.width;
        
        self.postedInButton.frame = CGRectMake(expandedLinkContentOffset.left, yBottom - (self.postedInButton.frame.size.height / 2), postedInButtonWidth, self.postedInButton.frame.size.height);
        
        yBottom = self.postedInButton.frame.origin.y + self.postedInButton.frame.size.height;
    }
    
    if (![self.titleLabel isHidden]) {
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [style setLineSpacing:(31 / 24)];
        
        CGFloat titleHeight = ceilf([self.titleLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width - (expandedLinkContentOffset.left + expandedLinkContentOffset.right), CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName: expandedLinkTitleLabelFont, NSParagraphStyleAttributeName: style} context:nil].size.height);
        self.titleLabel.frame = CGRectMake(expandedLinkContentOffset.left, yBottom + 16, self.frame.size.width - (expandedLinkContentOffset.left + expandedLinkContentOffset.right), titleHeight);
        yBottom = self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height;
    }
    
    if (![self.summaryLabel isHidden]) {
        CGFloat textViewHeight = ceilf([self.summaryLabel.text  boundingRectWithSize:CGSizeMake(self.frame.size.width - (expandedLinkContentOffset.left + expandedLinkContentOffset.right), CGFLOAT_MAX)  options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName: self.summaryLabel.font} context:nil].size.height);
        
        self.summaryLabel.frame = CGRectMake(expandedLinkContentOffset.left, yBottom + (self.titleLabel.text.length > 0 ? 8 : 16), self.frame.size.width - (expandedLinkContentOffset.left + expandedLinkContentOffset.right), textViewHeight);
        yBottom = self.summaryLabel.frame.origin.y + self.summaryLabel.frame.size.height;
    }
    
    if (![self.linkURLLabel isHidden]) {
        self.linkURLLabel.frame = CGRectMake(expandedLinkContentOffset.left, yBottom + 12, self.frame.size.width - (expandedLinkContentOffset.left + expandedLinkContentOffset.right), self.linkURLLabel.frame.size.height);
//        yBottom = self.linkURLLabel.frame.origin.y + self.linkURLLabel.frame.size.height;
    }
    
    // -- actions view
    self.activityView.frame = CGRectMake(0, self.contentView.frame.size.height - 30, self.frame.size.width, 30);
    self.activityLineSeparator.frame = CGRectMake(0, self.activityView.frame.origin.y - self.lineSeparator.frame.size.height, self.frame.size.width, self.lineSeparator.frame.size.height);
    
    self.lineSeparator.frame = CGRectMake(0, self.contentView.frame.size.height - self.lineSeparator.frame.size.height, self.frame.size.width, self.lineSeparator.frame.size.height);
}

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

- (void)setLink:(BFLink *)link {
    if ([link toDictionary] != [_link toDictionary]) {
        _link = link;
        
        // set tint color
        Camp *postedInCamp = self.link.attributes.attribution;
        
        UIColor *theme = [UIColor bonfireSecondaryColor];
        if (postedInCamp) {
            theme = [UIColor fromHex:self.link.attributes.attribution.attributes.color];
        }
        self.activityView.backgroundColor = [theme colorWithAlphaComponent:0.06f];
        self.activityView.tintColor = theme;
        self.tintColor = theme;
        self.imagePreviewView.backgroundColor = theme;
        
        if (link.attributes.linkTitle.length > 0) {
            NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
            [style setLineSpacing:(31 / 24)];
            NSAttributedString *title = [[NSAttributedString alloc] initWithString:link.attributes.linkTitle attributes:@{NSForegroundColorAttributeName: [UIColor bonfirePrimaryColor], NSFontAttributeName: expandedLinkTitleLabelFont, NSParagraphStyleAttributeName: style}];
            
            self.titleLabel.attributedText = title;
        }
        else {
            self.titleLabel.text = @"";
        }
        self.titleLabel.hidden = link.attributes.linkTitle.length == 0;
                
        self.summaryLabel.text = link.attributes.theDescription;
        
        self.activityView.link = link;
        
        if (postedInCamp) {
            // create camp attributed string
            NSMutableAttributedString *creatorString = [[NSMutableAttributedString alloc] init];
            
            UIFont *font = [UIFont systemFontOfSize:14.f weight:UIFontWeightBold];
            NSMutableAttributedString *spacer = [[NSMutableAttributedString alloc] initWithString:@" "];
            [spacer addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, spacer.length)];
            
            NSString *identifier = postedInCamp.attributes.title;
            if (postedInCamp.attributes.identifier.length > 0) {
                identifier = [@"#" stringByAppendingString:self.link.attributes.attribution.attributes.identifier];
            }
            
            NSMutableAttributedString *campTitleString = [[NSMutableAttributedString alloc] initWithString:identifier];
            [campTitleString addAttribute:NSForegroundColorAttributeName value:[UIColor bonfirePrimaryColor] range:NSMakeRange(0, campTitleString.length)];
            [campTitleString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, campTitleString.length)];
            
            [creatorString appendAttributedString:campTitleString];
            
            if ([postedInCamp isPrivate]) {
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
            else if ([postedInCamp.attributes.display.format isEqualToString:CAMP_DISPLAY_FORMAT_CHANNEL]) {
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
            
            [self.postedInButton setAttributedTitle:creatorString forState:UIControlStateNormal];
            
            BFAvatarView *postedInAvatarView = [self.postedInButton viewWithTag:10];
            postedInAvatarView.camp = postedInCamp;
            
            self.postedInButton.hidden = false;
        }
        else {
            self.postedInButton.hidden = true;
        }
        
        if (self.link.attributes.images.count > 0) {
            [self.imagePreviewView sd_setImageWithURL:[NSURL URLWithString:self.link.attributes.images[0]]];
        }
        else {
            self.imagePreviewView.image = nil;
        }
        
        self.linkURLLabel.hidden = self.link.attributes.canonicalUrl == nil || self.link.attributes.canonicalUrl.length == 0;
        if (![self.linkURLLabel isHidden]) {
            NSURL *url = [NSURL URLWithString:self.link.attributes.canonicalUrl];
            
            if (url) {
                NSString *host = url.host;
                if (host.length > 4 && [[host substringToIndex:4] isEqualToString:@"www."]) {
                    host = [host substringWithRange:NSMakeRange(4, host.length - 4)];
                }
                
                NSAttributedString *path = [[NSAttributedString alloc] initWithString:url.path attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:self.linkURLLabel.font.pointSize weight:UIFontWeightRegular], NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor]}];
                
                NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
                [style setLineBreakMode:NSLineBreakByTruncatingMiddle];
                
                NSMutableAttributedString *attributedLinkString = [[NSMutableAttributedString alloc] initWithString:host attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:self.linkURLLabel.font.pointSize weight:UIFontWeightSemibold], NSForegroundColorAttributeName: [UIColor bonfirePrimaryColor], NSParagraphStyleAttributeName: style}];
                [attributedLinkString appendAttributedString:path];
                
                // create spacer
                NSMutableAttributedString *spacer = [[NSMutableAttributedString alloc] initWithString:@" "];
                [spacer addAttribute:NSFontAttributeName value:self.linkURLLabel.font range:NSMakeRange(0, spacer.length)];
                [attributedLinkString appendAttributedString:spacer];
                
                NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
                attachment.image = [UIImage imageNamed:@"headerDetailDisclosureIcon"];
                [attachment setBounds:CGRectMake(0, roundf(self.linkURLLabel.font.capHeight - (attachment.image.size.height * .75))/2.f, attachment.image.size.width * .75, attachment.image.size.height * .75)];
                NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
                [attributedLinkString appendAttributedString:attachmentString];
                
                self.linkURLLabel.attributedText = attributedLinkString;
            }
        }
        else {
            self.linkURLLabel.text = @"";
        }
    }
}

+ (CGFloat)heightForLink:(BFLink *)link width:(CGFloat)contentWidth {
    CGFloat height = 0; // image height
    
    CGFloat postedInButtonHeight = 36;
    height += (postedInButtonHeight / 2);
    
    if (link.attributes.linkTitle.length > 0) {
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [style setLineSpacing:(31 / 24)];
        
        CGFloat titleHeight = [link.attributes.linkTitle boundingRectWithSize:CGSizeMake(contentWidth - (expandedLinkContentOffset.left + expandedLinkContentOffset.right), CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName: expandedLinkTitleLabelFont, NSParagraphStyleAttributeName: style} context:nil].size.height;
        height += 16 + titleHeight; // 16 above
    }
    
    if (link.attributes.theDescription.length > 0) {
        CGFloat textViewHeight = [link.attributes.theDescription boundingRectWithSize:CGSizeMake(contentWidth - (expandedLinkContentOffset.left + expandedLinkContentOffset.right), CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName: expandedLinkTextViewFont} context:nil].size.height;
        
        height += (link.attributes.linkTitle.length > 0 ? 8 : 16) + textViewHeight;
    }
    
    if (link.attributes.canonicalUrl.length > 0) {
        height += 12 + 16; // padding + {LABEL_HEIGHT}
    }
    
    CGFloat activityViewHeight = 24 + 30; // 24 padding above
    height += activityViewHeight;
    
    return expandedLinkContentOffset.top + height + expandedLinkContentOffset.bottom; // 1 = line separator
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    if (highlighted) {
        [UIView animateWithDuration:0.15f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.contentView.backgroundColor = [UIColor contentHighlightedColor];
        } completion:nil];
    }
    else {
        [UIView animateWithDuration:0.15f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.contentView.backgroundColor = [UIColor contentBackgroundColor];
        } completion:nil];
    }
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

@end
