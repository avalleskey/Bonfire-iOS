//
//  BotHeaderCell.m
//  Pulse
//
//  Created by Austin Valleskey on 10/1/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "BotHeaderCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <HapticHelper/HapticHelper.h>
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "Session.h"
#import "Launcher.h"
#import "UIColor+Palette.h"
#import "NSString+Validation.h"

@implementation BotHeaderCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        // general cell styling
        self.backgroundColor = [UIColor contentBackgroundColor];
        self.separatorInset = UIEdgeInsetsMake(0, 62, 0, 0);
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        CGFloat profilePicBorderWidth = 6;
        self.profilePictureContainer = [[UIView alloc] initWithFrame:CGRectMake(0, BOT_HEADER_EDGE_INSETS.top - profilePicBorderWidth, BOT_HEADER_AVATAR_SIZE + (profilePicBorderWidth * 2), BOT_HEADER_AVATAR_SIZE + (profilePicBorderWidth * 2))];
        self.profilePictureContainer.backgroundColor = [UIColor contentBackgroundColor];
        self.profilePictureContainer.layer.cornerRadius = self.profilePictureContainer.frame.size.height / 2;
        self.profilePictureContainer.layer.masksToBounds = false;
        self.profilePictureContainer.layer.shadowColor = [UIColor blackColor].CGColor;
        self.profilePictureContainer.layer.shadowOffset = CGSizeMake(0, 1);
        self.profilePictureContainer.layer.shadowRadius = 2.f;
        self.profilePictureContainer.layer.shadowOpacity = 0.12;
        self.profilePictureContainer.center = CGPointMake(self.contentView.frame.size.width / 2, self.profilePictureContainer.center.y);
        [self.contentView addSubview:self.profilePictureContainer];
        
        self.profilePicture = [[BFAvatarView alloc] initWithFrame:CGRectMake(profilePicBorderWidth, profilePicBorderWidth, BOT_HEADER_AVATAR_SIZE, BOT_HEADER_AVATAR_SIZE)];
        self.profilePicture.dimsViewOnTap = true;
        [self.profilePicture bk_whenTapped:^{
            if (self.profilePicture.bot.attributes.media.avatar.suggested.url.length > 0) {
                [Launcher expandImageView:self.profilePicture.imageView];
            }
        }];
        for (id interaction in self.profilePicture.interactions) {
            if (@available(iOS 13.0, *)) {
                if ([interaction isKindOfClass:[UIContextMenuInteraction class]]) {
                    [self.profilePicture removeInteraction:interaction];
                }
            }
        }
        [self.profilePictureContainer addSubview:self.profilePicture];
        
        self.textLabel.font = BOT_HEADER_DISPLAY_NAME_FONT;
        self.textLabel.textColor = [UIColor bonfirePrimaryColor];
        self.textLabel.textAlignment = NSTextAlignmentCenter;
        self.textLabel.numberOfLines = 0;
        self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.textLabel.backgroundColor = [UIColor clearColor];
        
        // username
        //UIFont *heavyItalicFont = [UIFont fontWithDescriptor:[[[UIFont systemFontOfSize:BOT_HEADER_USERNAME_FONT.pointSize weight:UIFontWeightHeavy] fontDescriptor] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic] size:BOT_HEADER_USERNAME_FONT.pointSize];
        self.detailTextLabel.font = [UIFont systemFontOfSize:BOT_HEADER_USERNAME_FONT.pointSize weight:UIFontWeightHeavy];
        self.detailTextLabel.textAlignment = NSTextAlignmentCenter;
        self.detailTextLabel.textColor = [UIColor bonfireSecondaryColor];
        self.detailTextLabel.numberOfLines = 0;
        self.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.detailTextLabel.backgroundColor = [UIColor clearColor];
        
        // bio
        self.bioLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectMake(24, 0, self.frame.size.width - 48, 18)];
        self.bioLabel.extendsLinkTouchArea = false;
        self.bioLabel.userInteractionEnabled = true;
        self.bioLabel.font = BOT_HEADER_BIO_FONT;
        self.bioLabel.textAlignment = NSTextAlignmentCenter;
        self.bioLabel.textColor = [UIColor bonfirePrimaryColor];
        self.bioLabel.numberOfLines = 0;
        self.bioLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.bioLabel.delegate = self;
        
        // bio link styling
        NSMutableDictionary *mutableActiveLinkAttributes = [NSMutableDictionary dictionary];
        [mutableActiveLinkAttributes setValue:[NSNumber numberWithBool:NO] forKey:(NSString *)kCTUnderlineStyleAttributeName];
        [mutableActiveLinkAttributes setValue:(__bridge id)[[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.1f] CGColor] forKey:(NSString *)kTTTBackgroundFillColorAttributeName];
        [mutableActiveLinkAttributes setValue:[NSNumber numberWithFloat:4.0f] forKey:(NSString *)kTTTBackgroundCornerRadiusAttributeName];
        [mutableActiveLinkAttributes setValue:[NSNumber numberWithFloat:0] forKey:(NSString *)kTTTBackgroundLineWidthAttributeName];
        self.bioLabel.activeLinkAttributes = mutableActiveLinkAttributes;
        
        // update tint color
        NSMutableDictionary *mutableLinkAttributes = [NSMutableDictionary dictionary];
        [mutableLinkAttributes setObject:[UIColor linkColor] forKey:(__bridge NSString *)kCTForegroundColorAttributeName];
        self.bioLabel.linkAttributes = mutableLinkAttributes;
        
        [self.contentView addSubview:self.bioLabel];
        
        self.detailsCollectionView = [[BFDetailsCollectionView alloc] initWithFrame:CGRectMake(BOT_HEADER_EDGE_INSETS.left, 0, [UIScreen mainScreen].bounds.size.width - BOT_HEADER_EDGE_INSETS.left - BOT_HEADER_EDGE_INSETS.right, 16)];
        [self.contentView addSubview:self.detailsCollectionView];
        
        self.followButton = [UserFollowButton buttonWithType:UIButtonTypeCustom];
        
        [self.followButton bk_whenTapped:^{
            // update state if possible
            
        }];
//        [self.contentView addSubview:self.followButton];
        
        self.lineSeparator = [[UIView alloc] init];
        self.lineSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
        [self.contentView addSubview:self.lineSeparator];
        
        #ifdef DEBUG
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
            if (state == UIGestureRecognizerStateBegan) {
                // recognized long press
                [Launcher openDebugView:self.bot];
            }
        }];
        [self addGestureRecognizer:longPress];
        #endif
    }
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
  if (!self.clipsToBounds && !self.hidden && self.alpha > 0) {
    for (UIView *subview in self.contentView.subviews.reverseObjectEnumerator) {
      CGPoint subPoint = [subview convertPoint:point fromView:self];
      UIView *result = [subview hitTest:subPoint withEvent:event];
      if (result != nil) {
        return result;
      }
    }
  }
  
  return [super hitTest:point withEvent:event];
}

- (void)attributedLabel:(TTTAttributedLabel *)label
   didSelectLinkWithURL:(NSURL *)url {
    NSLog(@"did select link with url: %@", url);
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        if ([url.scheme isEqualToString:LOCAL_APP_URI]) {
            // local url
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
                NSLog(@"opened url!");
            }];
        }
        else {
            // extern url
            [Launcher openURL:url.absoluteString];
        }
    }
}

- (void)updateBotStatus {
    BFContext *context = [[BFContext alloc] initWithDictionary:[self.bot.attributes.context toDictionary] error:nil];
    context.me.status = self.followButton.status;
    self.bot.attributes.context = context;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BotContextUpdated" object:self.bot];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat bottomY;
    
    CGFloat maxWidth = self.frame.size.width - (BOT_HEADER_EDGE_INSETS.left + BOT_HEADER_EDGE_INSETS.right);
    maxWidth = maxWidth > IPAD_CONTENT_MAX_WIDTH ? IPAD_CONTENT_MAX_WIDTH : maxWidth;
    
    // line separator
    self.lineSeparator.frame = CGRectMake(0, self.frame.size.height - (1 / [UIScreen mainScreen].scale), self.frame.size.width, (1 / [UIScreen mainScreen].scale));
    
    // profile picture
    self.profilePictureContainer.center = CGPointMake(self.contentView.frame.size.width / 2, self.profilePictureContainer.center.y);
    bottomY = BOT_HEADER_EDGE_INSETS.top + self.profilePicture.frame.size.height;
    
    // text label
    CGRect textLabelRect = [self.textLabel.attributedText boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil];
    self.textLabel.frame = CGRectMake(self.frame.size.width / 2 - maxWidth / 2, bottomY + BOT_HEADER_AVATAR_BOTTOM_PADDING, maxWidth, ceilf(textLabelRect.size.height));
    bottomY = self.textLabel.frame.origin.y + self.textLabel.frame.size.height;
    
    // detail text label
    CGRect detailLabelRect = [self.detailTextLabel.text boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.detailTextLabel.font} context:nil];
    self.detailTextLabel.frame = CGRectMake(self.textLabel.frame.origin.x, bottomY + BOT_HEADER_DISPLAY_NAME_BOTTOM_PADDING, self.textLabel.frame.size.width, ceilf(detailLabelRect.size.height));
    bottomY = self.detailTextLabel.frame.origin.y + self.detailTextLabel.frame.size.height;
    
    BOOL hasBio = self.bioLabel.attributedText.length > 0;
    self.bioLabel.hidden = !hasBio;
    if (hasBio) {
        CGRect bioLabelRect = [self.bioLabel.attributedText boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil];
        self.bioLabel.frame = CGRectMake(self.textLabel.frame.origin.x, bottomY + BOT_HEADER_USERNAME_BOTTOM_PADDING, self.textLabel.frame.size.width, ceilf(bioLabelRect.size.height));
        bottomY = self.bioLabel.frame.origin.y + self.bioLabel.frame.size.height;
    }
    
    BOOL hasDetails = self.detailsCollectionView.details.count > 0;
    self.detailsCollectionView.hidden = !hasDetails;
    if (hasDetails) {
        self.detailsCollectionView.frame = CGRectMake(BOT_HEADER_EDGE_INSETS.left, bottomY + (hasBio ? BOT_HEADER_BIO_BOTTOM_PADDING : BOT_HEADER_USERNAME_BOTTOM_PADDING) + BOT_HEADER_DETAILS_EDGE_INSETS.top, self.frame.size.width - (BOT_HEADER_EDGE_INSETS.left + BOT_HEADER_EDGE_INSETS.right), self.detailsCollectionView.collectionViewLayout.collectionViewContentSize.height);
        bottomY = self.detailsCollectionView.frame.origin.y + self.detailsCollectionView.frame.size.height;
    }
    
    self.followButton.frame = CGRectMake(12, bottomY + BOT_HEADER_FOLLOW_BUTTON_TOP_PADDING, self.frame.size.width - 24, 40);
}

- (BOOL)isCurrentUser {
    return [self.bot.identifier isEqualToString:[Session sharedInstance].currentUser.identifier];
}

- (void)setBot:(Bot *)bot {
    if (bot != _bot) {
        _bot = bot;
                
        self.tintColor = [UIColor fromHex:bot.attributes.color];
        
        self.profilePicture.bot = bot;
        
        // display name
        NSString *displayName;
        if (bot.attributes.displayName.length > 0) {
            displayName = bot.attributes.displayName;
        }
        else if (bot.attributes.identifier.length > 0) {
            displayName = [NSString stringWithFormat:@"@%@", bot.attributes.identifier];
        }
        else {
            displayName = [NSString stringWithFormat:@"@%@", bot.attributes.identifier];
        }
        NSMutableAttributedString *displayNameAttributedString = [[NSMutableAttributedString alloc] initWithString:displayName attributes:@{NSFontAttributeName:BOT_HEADER_DISPLAY_NAME_FONT}];
        if ([bot isVerified]) {
            NSMutableAttributedString *spacer = [[NSMutableAttributedString alloc] initWithString:@" "];
            [spacer addAttribute:NSFontAttributeName value:BOT_HEADER_DISPLAY_NAME_FONT range:NSMakeRange(0, spacer.length)];
            [displayNameAttributedString appendAttributedString:spacer];
            
            // verified icon ☑️
            NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
            attachment.image = [UIImage imageNamed:@"verifiedIcon_large"];
            [attachment setBounds:CGRectMake(0, roundf(BOT_HEADER_DISPLAY_NAME_FONT.capHeight - attachment.image.size.height)/2.f-1, attachment.image.size.width, attachment.image.size.height)];
            
            NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
            [displayNameAttributedString appendAttributedString:attachmentString];
        }
        self.textLabel.attributedText = displayNameAttributedString;
        
        // username
        self.detailTextLabel.text = [NSString stringWithFormat:@"@%@", bot.attributes.identifier];
        self.detailTextLabel.textColor = [UIColor fromHex:bot.attributes.color adjustForOptimalContrast:true];
        
        // bio
        if (bot.attributes.theDescription.length > 0) {
            NSMutableAttributedString *attrString = [[NSMutableAttributedString  alloc] initWithString:bot.attributes.theDescription];
            NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
            [style setLineSpacing:3.f];
            [style setAlignment:NSTextAlignmentCenter];
            [attrString addAttribute:NSParagraphStyleAttributeName
                               value:style
                               range:NSMakeRange(0, attrString.length)];
            [attrString addAttribute:NSFontAttributeName value:BOT_HEADER_BIO_FONT range:NSMakeRange(0, attrString.length)];
            [attrString addAttribute:NSForegroundColorAttributeName value:self.bioLabel.textColor range:NSMakeRange(0, attrString.length)];
            self.bioLabel.attributedText = attrString;
            
            NSArray *usernameRanges = [self.bot.attributes.theDescription rangesForUsernameMatches];
            for (NSValue *value in usernameRanges) {
                NSRange range = [value rangeValue];
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://user?username=%@", LOCAL_APP_URI, [[self.bot.attributes.theDescription substringWithRange:range] stringByReplacingOccurrencesOfString:@"@" withString:@""]]];
                [self.bioLabel addLinkToURL:url withRange:range];
            }
        
            NSArray *campRanges = [self.bot.attributes.theDescription rangesForCampTagMatches];
            for (NSValue *value in campRanges) {
                NSRange range = [value rangeValue];
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://camp?display_id=%@", LOCAL_APP_URI, [[self.bot.attributes.theDescription substringWithRange:range] stringByReplacingOccurrencesOfString:@"#" withString:@""]]];
                [self.bioLabel addLinkToURL:url withRange:range];
            }
        }
        else {
            self.bioLabel.text = @"";
        }
        
        NSMutableArray *details = [[NSMutableArray alloc] init];
//        if (bot.attributes.website.displayText.length > 0) {
//            BFDetailItem *item = [[BFDetailItem alloc] initWithType:BFDetailItemTypeWebsite value:bot.attributes.website.displayText action:nil];
//            [details addObject:item];
//        }
        
        self.detailsCollectionView.tintColor = self.detailTextLabel.textColor;
        
        self.detailsCollectionView.details = [details copy];
    }
}

+ (CGFloat)heightForBot:(Bot *)bot isLoading:(BOOL)loading {
    CGFloat maxWidth = [UIScreen mainScreen].bounds.size.width - (BOT_HEADER_EDGE_INSETS.left + BOT_HEADER_EDGE_INSETS.right);
    
    // knock out all the required bits first
    CGFloat height = BOT_HEADER_EDGE_INSETS.top + BOT_HEADER_AVATAR_SIZE + BOT_HEADER_AVATAR_BOTTOM_PADDING;
    
    // display name
    NSString *displayName;
    if (bot.attributes.displayName.length > 0) {
        displayName = bot.attributes.displayName;
    }
    else if (bot.attributes.identifier.length > 0) {
        displayName = [NSString stringWithFormat:@"@%@", bot.attributes.identifier];
    }
    else {
        displayName = [NSString stringWithFormat:@"@%@", bot.attributes.identifier];
    }
    NSMutableAttributedString *displayNameAttributedString = [[NSMutableAttributedString alloc] initWithString:displayName attributes:@{NSFontAttributeName:BOT_HEADER_DISPLAY_NAME_FONT}];
    if ([bot isVerified]) {
        NSMutableAttributedString *spacer = [[NSMutableAttributedString alloc] initWithString:@" "];
        [spacer addAttribute:NSFontAttributeName value:BOT_HEADER_DISPLAY_NAME_FONT range:NSMakeRange(0, spacer.length)];
        [displayNameAttributedString appendAttributedString:spacer];
        
        // verified icon ☑️
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        attachment.image = [UIImage imageNamed:@"verifiedIcon_large"];
        [attachment setBounds:CGRectMake(0, roundf(BOT_HEADER_DISPLAY_NAME_FONT.capHeight - attachment.image.size.height)/2.f-1, attachment.image.size.width, attachment.image.size.height)];
        
        NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
        [displayNameAttributedString appendAttributedString:attachmentString];
    }

    CGRect textLabelRect = [displayNameAttributedString boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) context:nil];
    CGFloat userDisplayNameHeight = ceilf(textLabelRect.size.height);
    height = height + userDisplayNameHeight;
    
    CGRect usernameRect = [[NSString stringWithFormat:@"@%@", bot.attributes.identifier] boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:BOT_HEADER_USERNAME_FONT} context:nil];
    CGFloat usernameHeight = ceilf(usernameRect.size.height);
    height = height + BOT_HEADER_DISPLAY_NAME_BOTTOM_PADDING + usernameHeight;
    
    if (bot.attributes.theDescription.length > 0) {
        NSMutableAttributedString *attrString = [[NSMutableAttributedString  alloc] initWithString:bot.attributes.theDescription];
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        [style setLineSpacing:3.f];
        [style setAlignment:NSTextAlignmentCenter];
        [attrString addAttribute:NSParagraphStyleAttributeName
                           value:style
                           range:NSMakeRange(0, attrString.length)];
        [attrString addAttribute:NSFontAttributeName value:BOT_HEADER_BIO_FONT range:NSMakeRange(0, attrString.length)];
        
        CGRect bioRect = [attrString boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)  context:nil];
        CGFloat bioHeight = ceilf(bioRect.size.height);
        height = height + BOT_HEADER_USERNAME_BOTTOM_PADDING + bioHeight;
    }
    
    if (loading || bot.identifier) {
        NSMutableArray *details = [[NSMutableArray alloc] init];
//        if (bot.attributes.website.displayUrl.length > 0) {
//            BFDetailItem *item = [[BFDetailItem alloc] initWithType:BFDetailItemTypeWebsite value:bot.attributes.website.displayUrl action:nil];
//            [details addObject:item];
//        }
        
        if (details.count > 0) {
            BFDetailsCollectionView *detailCollectionView = [[BFDetailsCollectionView alloc] initWithFrame:CGRectMake(BOT_HEADER_EDGE_INSETS.left, 0, [UIScreen mainScreen].bounds.size.width - BOT_HEADER_EDGE_INSETS.left - BOT_HEADER_EDGE_INSETS.right, 16)];
            detailCollectionView.delegate = detailCollectionView;
            detailCollectionView.dataSource = detailCollectionView;
            [detailCollectionView setDetails:details];
            
            height = height + (bot.attributes.theDescription.length > 0 ? BOT_HEADER_BIO_BOTTOM_PADDING : BOT_HEADER_USERNAME_BOTTOM_PADDING) +  BOT_HEADER_DETAILS_EDGE_INSETS.top + detailCollectionView.collectionViewLayout.collectionViewContentSize.height;
        }
    }
        
//    CGFloat userPrimaryActionHeight =  BOT_HEADER_FOLLOW_BUTTON_TOP_PADDING + 40;
//    height = height + userPrimaryActionHeight;
    
    // add bottom padding and line separator
    height = height + BOT_HEADER_EDGE_INSETS.bottom + (1 / [UIScreen mainScreen].scale);
    
    return height;
}

@end