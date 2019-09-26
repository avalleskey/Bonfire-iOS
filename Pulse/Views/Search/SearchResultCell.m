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

@implementation SearchResultCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor contentBackgroundColor];
        
        self.profilePicture = [[BFAvatarView alloc] initWithFrame:CGRectMake(12, self.frame.size.height / 2 - 21, 48, 48)];
        self.profilePicture.userInteractionEnabled = false;
        [self.contentView addSubview:self.profilePicture];
        
        self.textLabel.font = [UIFont systemFontOfSize:15.f weight:UIFontWeightSemibold];
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
    
    // image view
    self.profilePicture.frame = CGRectMake(12, self.frame.size.height / 2 - 24, 48, 48);
    
    // text label
    self.textLabel.frame = CGRectMake(70, 14, self.frame.size.width - 70 - 12 - (!self.checkIcon.isHidden ? 40 : 0), 18);
    
    // detail text label
    self.detailTextLabel.frame = CGRectMake(self.textLabel.frame.origin.x, self.textLabel.frame.origin.y + self.textLabel.frame.size.height + 2, self.textLabel.frame.size.width, 16);
    
    // check icon
    self.checkIcon.frame = CGRectMake(self.frame.size.width - self.checkIcon.frame.size.width - 16, self.frame.size.height / 2 - (self.checkIcon.frame.size.height / 2), self.checkIcon.frame.size.width, self.checkIcon.frame.size.height);
    
    if (!self.lineSeparator.isHidden) {
        // self.lineSeparator.frame = CGRectMake(postContentOffset.left, self.frame.size.height - self.lineSeparator.frame.size.height, self.frame.size.width - postContentOffset.left, self.lineSeparator.frame.size.height);
        self.lineSeparator.frame = CGRectMake(self.textLabel.frame.origin.x, self.frame.size.height - self.lineSeparator.frame.size.height, self.frame.size.width - self.textLabel.frame.origin.x, self.lineSeparator.frame.size.height);
    }
}

- (void)setUser:(User *)user {
    if (user != _user) {
        _user = user;
        _camp = nil;
        
        if (user) {
            self.profilePicture.user = user;
            self.textLabel.text = [NSString stringWithFormat:@"%@", self.user.attributes.details.displayName];
            
            // create detail text label
            self.detailTextLabel.text = [NSString stringWithFormat:@"@%@", self.user.attributes.details.identifier];
            self.detailTextLabel.textColor = [UIColor fromHex:self.user.attributes.details.color];
            self.detailTextLabel.font = [UIFont systemFontOfSize:self.detailTextLabel.font.pointSize weight:UIFontWeightSemibold];
        }
    }
}

- (void)setCamp:(Camp *)camp {
    if (camp != _camp) {
        _camp = camp;
        _user = nil;
        
        if (camp) {
            self.profilePicture.camp = camp;
            self.textLabel.text = self.camp.attributes.details.title;
            
            // create detail text label
            self.detailTextLabel.tintColor = [UIColor fromHex:self.camp.attributes.details.color];
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"#%@", camp.attributes.details.identifier] attributes:@{NSForegroundColorAttributeName: [UIColor fromHex:camp.attributes.details.color], NSFontAttributeName: [UIFont systemFontOfSize:self.detailTextLabel.font.pointSize weight:UIFontWeightSemibold]}];
            
            if ([camp.attributes.status.visibility isPrivate]) {
                // spacer
                [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:self.detailTextLabel.font.pointSize weight:UIFontWeightSemibold]}]];
                
                NSTextAttachment *lockAttachment = [[NSTextAttachment alloc] init];
                lockAttachment.image = [self colorImage:[UIImage imageNamed:@"inlinePostLockIcon"] color:self.detailTextLabel.tintColor];
                
                [lockAttachment setBounds:CGRectMake(0, roundf([UIFont systemFontOfSize:self.detailTextLabel.font.pointSize weight:UIFontWeightSemibold].capHeight - lockAttachment.image.size.height)/2.f, lockAttachment.image.size.width, lockAttachment.image.size.height)];
                
                NSAttributedString *lockAttachmentString = [NSAttributedString attributedStringWithAttachment:lockAttachment];
                [attributedString appendAttributedString:lockAttachmentString];
            }
            
            NSAttributedString *dotSeparator = [[NSAttributedString alloc] initWithString:@"  ·  " attributes:@{NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor], NSFontAttributeName: [UIFont systemFontOfSize:self.detailTextLabel.font.pointSize weight:UIFontWeightRegular]}];
            
            if (camp.attributes.summaries.counts.members > 0) {
                if (attributedString.string.length > 0) {
                    [attributedString appendAttributedString:dotSeparator];
                }
                
                NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
                attachment.image = [UIImage imageNamed:@"details_label_members"];
                [attachment setBounds:CGRectMake(0, roundf(self.detailTextLabel.font.capHeight - attachment.image.size.height)/2.f, attachment.image.size.width, attachment.image.size.height)];
                NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
                [attributedString appendAttributedString:attachmentString];
                           
                NSString *detailText = [NSString stringWithFormat:@" %ld", (long)camp.attributes.summaries.counts.members];
                NSAttributedString *detailAttributedText = [[NSAttributedString alloc] initWithString:detailText attributes:@{NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor], NSFontAttributeName: [UIFont systemFontOfSize:self.detailTextLabel.font.pointSize weight:UIFontWeightSemibold]}];
                [attributedString appendAttributedString:detailAttributedText];
            }
            
            self.detailTextLabel.attributedText = attributedString;
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
            self.backgroundColor = [UIColor contentHighlightedColor];
        } completion:nil];
    }
    else {
        [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.backgroundColor = [UIColor contentBackgroundColor];
        } completion:nil];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
@end
