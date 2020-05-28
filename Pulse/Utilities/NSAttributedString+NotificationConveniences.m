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
    if (activity.attributes.actioner.attributes.identifier) {
        [variables setObject:[NSString stringWithFormat:@"@%@", activity.attributes.actioner.attributes.identifier] forKey:@"$actioner.username"];
    }
    if (activity.attributes.actioner.attributes.displayName) {
        [variables setObject:activity.attributes.actioner.attributes.displayName forKey:@"$actioner.displayName"];
    }
    if (activity.attributes.actioner.attributes.bio) {
        [variables setObject:activity.attributes.actioner.attributes.bio forKey:@"$actioner.bio"];
    }
    if (activity.attributes.camp.attributes.title) {
        [variables setObject:activity.attributes.camp.attributes.title forKey:@"$camp.title"];
    }
    if (activity.attributes.camp.attributes.theDescription) {
        [variables setObject:activity.attributes.camp.attributes.theDescription forKey:@"$camp.description"];
    }
    if (activity.attributes.camp.attributes.identifier) {
        [variables setObject:[NSString stringWithFormat:@"#%@", activity.attributes.camp.attributes.identifier] forKey:@"$camp.identifier"];
    }
    if (activity.attributes.post.attributes.message) {
        [variables setObject:activity.attributes.post.attributes.message forKey:@"$post.message"];
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
            attributedPart = [[NSMutableAttributedString alloc] initWithString:[variables objectForKey:part] attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:fontSize weight:UIFontWeightSemibold], NSForegroundColorAttributeName: [UIColor bonfirePrimaryColor]}];
            
            /*
            [attributedString addAttribute:NSLinkAttributeName
                                     value:@"username://marcelofabri_"
                                     range:[[attributedString string] rangeOfString:@"@marcelofabri_"]];*/
        }
        else {
            attributedPart = [[NSMutableAttributedString alloc] initWithString:part attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:fontSize weight:UIFontWeightRegular], NSForegroundColorAttributeName: [UIColor bonfirePrimaryColor]}];
        }
        
        [attributedString appendAttributedString:attributedPart];
    }
    
    NSString *timeStamp = [NSDate mysqlDatetimeFormattedAsTimeAgo:activity.attributes.createdAt withForm:TimeAgoShortForm];
    
    NSMutableAttributedString *timeStampString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@", timeStamp]];
    [timeStampString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:fontSize weight:UIFontWeightRegular] range:NSMakeRange(0, timeStampString.length)];
    [timeStampString addAttribute:NSForegroundColorAttributeName value:[UIColor bonfireSecondaryColor] range:NSMakeRange(0, timeStampString.length)];
    [attributedString appendAttributedString:timeStampString];
    
    return attributedString;
}

@end
