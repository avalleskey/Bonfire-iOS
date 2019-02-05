//
//  BFDetailsLabel.m
//  Pulse
//
//  Created by Austin Valleskey on 1/17/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFDetailsLabel.h"
#import "Session.h"
#import "UIColor+Palette.h"

@implementation BFDetailsLabel

- (id)init {
    self = [super init];
    if (self) {
        _details = @[];
    }
    return self;
}

+ (NSDictionary *)BFDetailWithType:(BFDetailType)type value:(id)value action:(PatternTapResponder _Nullable)tapResponder {
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    if (type != 0) {
        [dictionary setObject:[NSNumber numberWithInt:(int)type] forKey:@"type"];
    }
    if (value != nil) {
        [dictionary setObject:[NSString stringWithFormat:@"%@", value] forKey:@"value"];
    }
    if (tapResponder != nil) {
        [dictionary setObject:tapResponder forKey:@"action"];
    }
    
    return [dictionary copy];
}

- (void)setDetails:(NSArray *)details {
    if (details != _details) {
        _details = details;
        
        self.attributedText = [BFDetailsLabel attributedStringForDetails:_details linkColor:self.tintColor];
        
        CGSize size = [self.attributedText boundingRectWithSize:CGSizeMake(self.frame.size.width, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil].size;
        
        CGRect frame = self.frame;
        frame.size.height = size.height;
    }
}

+ (NSAttributedString *)attributedStringForDetails:(NSArray *)details linkColor:(UIColor * _Nullable)linkColor {
    UIFont *font = [UIFont systemFontOfSize:13.f];
    UIColor *color = [UIColor colorWithWhite:0.33f alpha:1];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
    for (int i = 0; i < details.count; i++) {
        if (![details[i] objectForKey:@"type"] || ![details[i] objectForKey:@"value"])
            continue;
        
        int type = [details[i][@"type"] intValue];
        
        UIImage *typeImage;
        NSString *valueString = [NSString stringWithFormat:@"%@", details[i][@"value"]];
        if (type == BFDetailTypePrivacyPublic) {
            typeImage = [UIImage imageNamed:@"details_label_public"];
            valueString = @"Public";
        }
        else if (type == BFDetailTypePrivacyPrivate) {
            typeImage = [UIImage imageNamed:@"details_label_private"];
            valueString = @"Private";
        }
        else if (type == BFDetailTypeMembers) {
            typeImage = [UIImage imageNamed:@"details_label_members"];
            if (valueString.length == 0) {
                valueString = @"0";
            }
            DefaultsRoomMembersTitle *membersTitle = [Session sharedInstance].defaults.room.membersTitle;
            valueString = [valueString stringByAppendingString:[NSString stringWithFormat:@" %@", ([valueString isEqualToString:@"1"] ? [membersTitle.singular lowercaseString] : [membersTitle.plural lowercaseString])]];
        }
        else if (type == BFDetailTypeLocation) {
            typeImage = [UIImage imageNamed:@"details_label_location"];
            if (valueString.length == 0) {
                continue;
            }
        }
        else if (type == BFDetailTypeWebsite) {
            typeImage = [UIImage imageNamed:@"details_label_link"];
            if (valueString.length == 0) {
                continue;
            }
            valueString = [valueString stringByReplacingOccurrencesOfString:@"http://" withString:@""];
            valueString = [valueString stringByReplacingOccurrencesOfString:@"https://" withString:@""];
        }
        
        if (attributedString.length > 0) {
            NSMutableAttributedString *spacer = [[NSMutableAttributedString alloc] initWithString:@"    "];
            [spacer addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, spacer.length)];
            [spacer addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, spacer.length)];
            [attributedString appendAttributedString:spacer];
        }
        
        // add icon
        if (typeImage) {
            NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
            attachment.image = typeImage;
            [attachment setBounds:CGRectMake(0, roundf(font.capHeight - attachment.image.size.height)/2.f, attachment.image.size.width, attachment.image.size.height)];
            
            NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
            [attributedString appendAttributedString:attachmentString];
        }
        
        NSMutableAttributedString *mutableValueString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@", valueString]];
        [mutableValueString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, mutableValueString.length)];
        
        // add action if given
        if ([details[i] objectForKey:@"action"]) {
            [mutableValueString addAttribute:RLTapResponderAttributeName value:[details[i] objectForKey:@"action"] range:NSMakeRange(0, mutableValueString.length)];
            
            if (!linkColor) {
                linkColor = [UIColor bonfireBlue];
            }
            [mutableValueString addAttribute:NSForegroundColorAttributeName value:linkColor range:NSMakeRange(0, mutableValueString.length)];
            [mutableValueString addAttribute:RLHighlightedForegroundColorAttributeName value:[linkColor colorWithAlphaComponent:0.5] range:NSMakeRange(0, mutableValueString.length)];
        }
        else {
            [mutableValueString addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, mutableValueString.length)];
        }
        
        [attributedString appendAttributedString:mutableValueString];
    }
    
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineSpacing:2.f];
    [style setAlignment:NSTextAlignmentCenter];
    [attributedString addAttribute:NSParagraphStyleAttributeName
                             value:style
                             range:NSMakeRange(0, attributedString.length)];
    
    return attributedString;
}

@end
