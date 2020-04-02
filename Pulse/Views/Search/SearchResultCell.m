//
//  SearchResultCell.m
//  Pulse
//
//  Created by Austin Valleskey on 10/1/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "SearchResultCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIColor+Palette.h"
#import "Session.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>

@implementation SearchResultCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor contentBackgroundColor];
        
        self.profilePicture = [[BFAvatarView alloc] initWithFrame:CGRectMake(12, self.frame.size.height / 2 - 21, 42, 42)];
        self.profilePicture.userInteractionEnabled = false;
        [self.contentView addSubview:self.profilePicture];
        
        self.textLabel.font = [UIFont systemFontOfSize:15.f weight:UIFontWeightBold];
        self.textLabel.textColor = [UIColor bonfirePrimaryColor];
        self.textLabel.backgroundColor = [UIColor clearColor];
        
        self.detailTextLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightRegular];
        self.detailTextLabel.textAlignment = NSTextAlignmentLeft;
        self.detailTextLabel.textColor = [UIColor bonfireSecondaryColor];
        self.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        self.detailTextLabel.backgroundColor = [UIColor clearColor];
        
        // general cell styling
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, (1 / [UIScreen mainScreen].scale))];
        self.lineSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
        [self addSubview:self.lineSeparator];
        
        self.contextButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.contextButton.frame = CGRectMake(0, 0, 24, 24);
        self.contextButton.contentMode = UIViewContentModeCenter;
        self.contextButton.layer.cornerRadius = self.contextButton.frame.size.height / 2;
        self.contextButton.backgroundColor = [UIColor fromHex:@"0076ff" adjustForOptimalContrast:true];
        self.contextButton.layer.masksToBounds = true;
        self.contextButton.hidden = true;
        self.contextButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        self.contextButton.titleLabel.font = [UIFont systemFontOfSize:12.f weight:UIFontWeightHeavy];
        self.contextButton.userInteractionEnabled = false;
        [self.contentView addSubview:self.contextButton];
        
        self.actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.actionButton.backgroundColor = [UIColor bonfireBrand];
        self.actionButton.layer.cornerRadius = 10.f;
        self.actionButton.layer.masksToBounds = true;
        self.actionButton.hidden = true;
        self.actionButton.titleLabel.font = [UIFont systemFontOfSize:self.textLabel.font.pointSize weight:UIFontWeightBold];
        [self.actionButton bk_whenTapped:^{
            if (self.user) {
                self.user.attributes.context.me.status = USER_STATUS_LOADING;
                [BFAPI followUser:self.user completion:^(BOOL success, id  _Nullable responseObject) {
                    if (success) {
                        if ([responseObject isKindOfClass:[User class]] && [((User *)responseObject).identifier isEqualToString:self.user.identifier]) {
                            self.user = (User *)responseObject;
                            [self layoutSubviews];
                        }
                    }
                }];
            }
            else if (self.camp) {
                self.camp.attributes.context.camp.status = CAMP_STATUS_LOADING;
                [BFAPI followCamp:self.camp completion:^(BOOL success, id  _Nullable responseObject) {
                    if (success) {
                        if ([responseObject isKindOfClass:[Camp class]] && [((Camp *)responseObject).identifier isEqualToString:self.camp.identifier]) {
                            self.camp = (Camp *)responseObject;
                            [self layoutSubviews];
                        }
                    }
                }];
            }
        }];
        [self.actionButton bk_addEventHandler:^(id sender) {
            [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.actionButton.alpha = 0.5;
            } completion:nil];
        } forControlEvents:UIControlEventTouchDown];
        [self.actionButton bk_addEventHandler:^(id sender) {
            [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.actionButton.alpha = 1;
            } completion:nil]; } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];

        [self.contentView addSubview:self.actionButton];
        
        self.checkIcon = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
        self.checkIcon.image = [[UIImage imageNamed:@"tableCellCheckIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.checkIcon.tintColor = self.tintColor;
        self.checkIcon.hidden = true;
        [self.contentView addSubview:self.checkIcon];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    UIEdgeInsets textEdgeInsets = UIEdgeInsetsMake(12, 64, 14, 12);
    
    // image view
    self.profilePicture.frame = CGRectMake(12, self.frame.size.height / 2 - 21, 42, 42);
    
    // check icon
    if (![self.checkIcon isHidden]) {
        self.actionButton.hidden = true;
        self.contextButton.hidden = true;
        
        textEdgeInsets.right += 4;
        self.checkIcon.frame = CGRectMake(self.frame.size.width - self.checkIcon.frame.size.width - textEdgeInsets.right, self.frame.size.height / 2 - (self.checkIcon.frame.size.height / 2), self.checkIcon.frame.size.width, self.checkIcon.frame.size.height);
        textEdgeInsets.right = (self.frame.size.width - self.checkIcon.frame.origin.x) + 10;
    }
    else if (![self.actionButton isHidden]) {
        self.checkIcon.hidden = true;
        self.contextButton.hidden = true;
        
        CGFloat buttonSidePadding = 14;
        CGFloat actionButtonWidth = (self.actionButton.intrinsicContentSize.width + (buttonSidePadding * 2));
        self.actionButton.frame = CGRectMake(self.frame.size.width - actionButtonWidth - textEdgeInsets.right, self.frame.size.height / 2 - (34 / 2), actionButtonWidth, 34);
        textEdgeInsets.right = (self.frame.size.width - self.actionButton.frame.origin.x) + 10;
    }
    else if (![self.contextButton isHidden]) {
        self.checkIcon.hidden = true;
        self.actionButton.hidden = true;
        
        textEdgeInsets.right += 4;
        CGFloat buttonSidePadding = 2;
        CGFloat actionButtonWidth = self.contextButton.currentTitle.length > 1 ? MAX(self.contextButton.frame.size.height, self.contextButton.intrinsicContentSize.width + (buttonSidePadding * 2)) : self.contextButton.frame.size.height;
        self.contextButton.frame = CGRectMake(self.frame.size.width - actionButtonWidth - textEdgeInsets.right, self.frame.size.height / 2 - (self.contextButton.frame.size.height / 2), actionButtonWidth, self.contextButton.frame.size.height);
        textEdgeInsets.right = (self.frame.size.width - self.contextButton.frame.origin.x) + 10;
    }
    
    // text label
    self.textLabel.frame = CGRectMake(textEdgeInsets.left, textEdgeInsets.top, self.frame.size.width - textEdgeInsets.left - textEdgeInsets.right, 18);
    
    // detail text label
    self.detailTextLabel.frame = CGRectMake(self.textLabel.frame.origin.x, self.textLabel.frame.origin.y + self.textLabel.frame.size.height + 2, self.textLabel.frame.size.width, 16);
    
    if (!self.lineSeparator.isHidden) {
        // self.lineSeparator.frame = CGRectMake(postContentOffset.left, self.frame.size.height - self.lineSeparator.frame.size.height, self.frame.size.width - postContentOffset.left, self.lineSeparator.frame.size.height);
        self.lineSeparator.frame = CGRectMake(self.textLabel.frame.origin.x, self.frame.size.height - self.lineSeparator.frame.size.height, self.frame.size.width - self.textLabel.frame.origin.x, self.lineSeparator.frame.size.height);
    }
    
    if (self.camp) {
        [self renderCampDetailLabel];
    }
}

- (void)renderCampDetailLabel {
    if  (!self.camp) {
        // safeguard
        return;
    }
    
    // create detail text label
    self.detailTextLabel.tintColor = [UIColor fromHex:self.camp.attributes.color adjustForOptimalContrast:true];
    NSMutableAttributedString *attributedString = [NSMutableAttributedString new];
    
    if (self.camp.attributes.identifier.length > 0) {
        attributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"#%@", self.camp.attributes.identifier] attributes:@{NSForegroundColorAttributeName: [UIColor fromHex:self.camp.attributes.color adjustForOptimalContrast:true], NSFontAttributeName: [UIFont systemFontOfSize:self.detailTextLabel.font.pointSize weight:UIFontWeightSemibold]}];
        
        UIFont *camptagFont = [UIFont systemFontOfSize:self.detailTextLabel.font.pointSize weight:UIFontWeightSemibold];
        if ([self.camp isPrivate]) {
            // spacer
            [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:@{NSFontAttributeName: camptagFont}]];
            
            NSTextAttachment *lockAttachment = [[NSTextAttachment alloc] init];
            lockAttachment.image = [self colorImage:[UIImage imageNamed:@"details_label_private"] color:self.detailTextLabel.tintColor];
            
            CGFloat attachmentHeight = MIN(ceilf(self.detailTextLabel.font.lineHeight * 0.7), ceilf(lockAttachment.image.size.height));
            CGFloat attachmentWidth = ceilf(attachmentHeight * (lockAttachment.image.size.width / lockAttachment.image.size.height));
            
            [lockAttachment setBounds:CGRectMake(0, roundf(camptagFont.capHeight - attachmentHeight)/2.f, attachmentWidth, attachmentHeight)];
            
            NSAttributedString *lockAttachmentString = [NSAttributedString attributedStringWithAttachment:lockAttachment];
            [attributedString appendAttributedString:lockAttachmentString];
        }
        else if ([self.camp.attributes.display.format isEqualToString:CAMP_DISPLAY_FORMAT_CHANNEL]) {
             // spacer
             [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:self.detailTextLabel.font.pointSize weight:UIFontWeightSemibold]}]];
             
             NSTextAttachment *sourceAttachment = [[NSTextAttachment alloc] init];
             sourceAttachment.image = [self colorImage:[UIImage imageNamed:@"details_label_source"] color:self.detailTextLabel.tintColor];
             
            CGFloat attachmentHeight = MIN(ceilf(self.detailTextLabel.font.lineHeight * 0.7), ceilf(sourceAttachment.image.size.height));
            CGFloat attachmentWidth = ceilf(attachmentHeight * (sourceAttachment.image.size.width / sourceAttachment.image.size.height));
            
            [sourceAttachment setBounds:CGRectMake(0, roundf(camptagFont.capHeight - attachmentHeight)/2.f, attachmentWidth, attachmentHeight)];
                                 
             NSAttributedString *lockAttachmentString = [NSAttributedString attributedStringWithAttachment:sourceAttachment];
             [attributedString appendAttributedString:lockAttachmentString];
        }
    }
    
    if ((!self.hideCampMemberCount || attributedString.length == 0) && ![self.camp isFeed]) {
        NSInteger membersCount = self.camp.attributes.summaries.counts.members;
        NSString *detailText;
        
        if (attributedString.length > 0) {
            NSAttributedString *dotSeparator = [[NSAttributedString alloc] initWithString:@"  ·  " attributes:@{NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor], NSFontAttributeName: [UIFont systemFontOfSize:self.detailTextLabel.font.pointSize weight:UIFontWeightRegular]}];
            
            [attributedString appendAttributedString:dotSeparator];
            
            
            detailText = [NSString stringWithFormat:@" %ld", (long)self.camp.attributes.summaries.counts.members];
        }
        else {
            detailText = [NSString stringWithFormat:@" %ld %@%@", (long)self.camp.attributes.summaries.counts.members, ([self.camp isChannel] ? @"subscriber" : @"member"), (membersCount == 1 ? @"" : @"s")];
        }
        
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        attachment.image = [self colorImage:[UIImage imageNamed:@"details_label_members"] color:[UIColor bonfireSecondaryColor]];
        [attachment setBounds:CGRectMake(0, roundf(self.detailTextLabel.font.capHeight - attachment.image.size.height)/2.f, attachment.image.size.width, attachment.image.size.height)];
        NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
        [attributedString appendAttributedString:attachmentString];
                  
        NSAttributedString *detailAttributedText = [[NSAttributedString alloc] initWithString:detailText attributes:@{NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor], NSFontAttributeName: [UIFont systemFontOfSize:self.detailTextLabel.font.pointSize weight:UIFontWeightSemibold]}];
        [attributedString appendAttributedString:detailAttributedText];
    }
    
    self.detailTextLabel.attributedText = attributedString;
}

- (void)setUser:(User *)user {
    if (user != _user) {
        _bot = nil;
        _camp = nil;
        _user = user;
        
        if (user) {
            self.tintColor = [UIColor fromHex:user.attributes.color adjustForOptimalContrast:true];
            self.checkIcon.tintColor = self.tintColor;
            
            self.profilePicture.user = user;
            if (self.user.attributes.displayName.length > 0) {
                self.textLabel.text = self.user.attributes.displayName;
            }
            else {
                self.textLabel.text = @"Unknown User";
            }
            
            // create detail text label
            if (self.user.attributes.identifier.length > 0) {
                self.detailTextLabel.text = [NSString stringWithFormat:@"@%@", self.user.attributes.identifier];
                self.detailTextLabel.textColor = [UIColor fromHex:self.user.attributes.color adjustForOptimalContrast:true];
            }
            else {
                self.detailTextLabel.text = @"---";
                self.detailTextLabel.textColor = [UIColor bonfireSecondaryColor];
            }
            self.detailTextLabel.font = [UIFont systemFontOfSize:self.detailTextLabel.font.pointSize weight:UIFontWeightSemibold];
            
            self.actionButton.hidden = !self.showActionButton || !([user.attributes.context.me.status isEqualToString:USER_STATUS_NO_RELATION] || [user.attributes.context.me.status isEqualToString:USER_STATUS_FOLLOWED]);
            if (![self.actionButton isHidden]) {
                [self.actionButton setTitle:@"Follow" forState:UIControlStateNormal];
                self.actionButton.backgroundColor = [UIColor fromHex:user.attributes.color adjustForOptimalContrast:true];
                [self.actionButton setTitleColor:[UIColor highContrastForegroundForBackground:self.actionButton.backgroundColor] forState:UIControlStateNormal];
            }
            self.contextButton.hidden = true;
        }
    }
}

- (void)setBot:(Bot *)bot {
    if (bot != _bot) {
        _user = nil;
        _camp = nil;
        _bot = bot;
        
        if (bot) {
            self.tintColor = [UIColor fromHex:bot.attributes.color adjustForOptimalContrast:true];
            self.checkIcon.tintColor = self.tintColor;
            
            self.profilePicture.bot = bot;
            if (self.bot.attributes.displayName.length > 0) {
                self.textLabel.text = self.bot.attributes.displayName;
            }
            else {
                self.textLabel.text = @"Unknown Bot";
            }
            
            // create detail text label
            if (self.bot.attributes.identifier.length > 0) {
                self.detailTextLabel.text = [NSString stringWithFormat:@"@%@", self.bot.attributes.identifier];
                self.detailTextLabel.textColor = [UIColor fromHex:self.bot.attributes.color adjustForOptimalContrast:true];
                self.detailTextLabel.font = [UIFont systemFontOfSize:self.detailTextLabel.font.pointSize weight:UIFontWeightSemibold];
            }
            else {
                self.detailTextLabel.text = @"---";
                self.detailTextLabel.textColor = [UIColor bonfireSecondaryColor];
            }
            
            self.actionButton.hidden = true;
            self.contextButton.hidden = true;
        }
    }
}

- (void)setCamp:(Camp *)camp {
    if (camp != _camp) {
        _user = nil;
        _bot = nil;
        _camp = camp;
        
        if (camp) {
            self.tintColor = [UIColor fromHex:camp.attributes.color adjustForOptimalContrast:true];
            self.checkIcon.tintColor = self.tintColor;
            
            self.profilePicture.camp = camp;
            if (self.camp.attributes.title.length > 0) {
                self.textLabel.text = self.camp.attributes.title;
            }
            else {
                self.textLabel.text = @"Unknown Camp";
            }
            
            [self renderCampDetailLabel];
            
            NSInteger new = camp.attributes.summaries.counts.postsNewForyou;
            float scoreIndex = camp.attributes.summaries.counts.scoreIndex;
                        
            self.actionButton.hidden = !self.showActionButton || !([camp.attributes.context.camp.status isEqualToString:CAMP_STATUS_NO_RELATION] || [camp.attributes.context.camp.status isEqualToString:CAMP_STATUS_LEFT]);
            self.contextButton.hidden = ![self.actionButton isHidden] || (new == 0 && scoreIndex == 0);
            if (![self.actionButton isHidden]) {
                if ([camp isChannel] || [camp isFeed]) {
                    [self.actionButton setTitle:@"Subscribe" forState:UIControlStateNormal];
                }
                else {
                    [self.actionButton setTitle:@"Join" forState:UIControlStateNormal];
                }
                self.actionButton.backgroundColor = [[UIColor fromHex:camp.attributes.color adjustForOptimalContrast:true] colorWithAlphaComponent:0.1];
                [self.actionButton setTitleColor:[UIColor fromHex:camp.attributes.color adjustForOptimalContrast:true] forState:UIControlStateNormal];
            }
            else if (![self.contextButton isHidden]) {
                if (new > 0) {
                    [self.contextButton setBackgroundImage:nil forState:UIControlStateNormal];
                    if (new > 9) {
                        [self.contextButton setTitle:@"9+" forState:UIControlStateNormal];
                    }
                    else {
                        [self.contextButton setTitle:[NSString stringWithFormat:@"%lu", new] forState:UIControlStateNormal];
                    }
                    self.contextButton.backgroundColor = [UIColor fromHex:@"0076ff" adjustForOptimalContrast:YES];
                }
                else if (scoreIndex > 0) {
                    self.contextButton.backgroundColor = [UIColor fromHex:camp.scoreColor];
                    [self.contextButton setBackgroundImage:[UIImage imageNamed:@"hotIcon"] forState:UIControlStateNormal];
                    [self.contextButton setTitle:@"" forState:UIControlStateNormal];
                }
                else {
                    [self.contextButton setBackgroundImage:nil forState:UIControlStateNormal];
                    [self.contextButton setTitle:@"" forState:UIControlStateNormal];
                    self.contextButton.hidden = true;
                }
            }
        }
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

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    if (highlighted) {
        [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            if (self.backgroundColor == [UIColor contentBackgroundColor]) {
                self.contentView.backgroundColor = [UIColor contentHighlightedColor];
            }
            else {
                self.contentView.backgroundColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.04f];
            }
        } completion:nil];
    }
    else {
        [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.contentView.backgroundColor = self.backgroundColor;
        } completion:nil];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
@end
