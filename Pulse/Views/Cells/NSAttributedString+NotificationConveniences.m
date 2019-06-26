//
//  NotificationAttributedString.m
//  Pulse
//
//  Created by Austin Valleskey on 12/5/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "NSAttributedString+NotificationConveniences.h"
#import "NSDate+NVTimeAgo.h"
#import "Session.h"
#import "UIColor+Palette.h"

@implementation NSAttributedString (NotificationConveniences)

+ (NSAttributedString *)attributedStringForActivity:(UserActivity *)activity {
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
    
    CGFloat fontSize = 15.f;
    
    // available variables
    NSMutableDictionary *variables = [[NSMutableDictionary alloc] init];
    if (activity.attributes.actioner.attributes.details.identifier) {
        [variables setObject:[NSString stringWithFormat:@"@%@", activity.attributes.actioner.attributes.details.identifier] forKey:@"$actioner.username"];
    }
    if (activity.attributes.actioner.attributes.details.displayName) {
        [variables setObject:activity.attributes.actioner.attributes.details.displayName forKey:@"$actioner.displayName"];
    }
    if (activity.attributes.actioner.attributes.details.bio) {
        [variables setObject:activity.attributes.actioner.attributes.details.bio forKey:@"$actioner.bio"];
    }
    if (activity.attributes.camp.attributes.details.title) {
        [variables setObject:activity.attributes.camp.attributes.details.title forKey:@"$camp.title"];
    }
    if (activity.attributes.camp.attributes.details.theDescription) {
        [variables setObject:activity.attributes.camp.attributes.details.theDescription forKey:@"$camp.description"];
    }
    if (activity.attributes.camp.attributes.details.identifier) {
        [variables setObject:[NSString stringWithFormat:@"#%@", activity.attributes.camp.attributes.details.identifier] forKey:@"$camp.identifier"];
    }
    if (activity.attributes.post.attributes.details.message) {
        [variables setObject:activity.attributes.post.attributes.details.message forKey:@"$post.message"];
    }
    
    NSArray *stringParts = @[];

    NSDictionary *formats = [Session sharedInstance].defaults.notifications;
    
    NSString *key = [NSString stringWithFormat:@"%u", activity.attributes.type];
    
    if ([[formats allKeys] containsObject:key]) {
        NSError *error;
        DefaultsNotificationsFormat *notificationFormat = [[DefaultsNotificationsFormat alloc] initWithDictionary:formats[key] error:&error];
        if (!error) {
            stringParts = notificationFormat.stringParts;
        }
    }
    
    for (NSString *part in stringParts) {
        NSMutableAttributedString *attributedPart;
        if ([[variables allKeys] containsObject:part]) {
            attributedPart = [[NSMutableAttributedString alloc] initWithString:[variables objectForKey:part] attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:fontSize weight:UIFontWeightSemibold], NSForegroundColorAttributeName: [UIColor bonfireBlack]}];
            
            /*
            [attributedString addAttribute:NSLinkAttributeName
                                     value:@"username://marcelofabri_"
                                     range:[[attributedString string] rangeOfString:@"@marcelofabri_"]];*/
        }
        else {
            attributedPart = [[NSMutableAttributedString alloc] initWithString:part attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:fontSize weight:UIFontWeightRegular], NSForegroundColorAttributeName: [UIColor bonfireBlack]}];
        }
        
        [attributedString appendAttributedString:attributedPart];
    }
    
    NSString *timeStamp = [NSDate mysqlDatetimeFormattedAsTimeAgo:activity.attributes.createdAt withForm:TimeAgoShortForm];
    
    NSMutableAttributedString *timeStampString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@", timeStamp]];
    [timeStampString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:fontSize weight:UIFontWeightRegular] range:NSMakeRange(0, timeStampString.length)];
    [timeStampString addAttribute:NSForegroundColorAttributeName value:[UIColor bonfireGray] range:NSMakeRange(0, timeStampString.length)];
    [attributedString appendAttributedString:timeStampString];
    
    return attributedString;
}

@end
