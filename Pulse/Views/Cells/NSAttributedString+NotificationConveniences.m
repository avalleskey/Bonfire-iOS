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

@implementation NSAttributedString (NotificationConveniences)

+ (NSAttributedString *)attributedStringForType:(NotificationType)notificationType {
    // TODO: Replace with actual user
    User *user = [Session sharedInstance].currentUser;
    
    NSString *displayName = user == nil ? @"Unkown User" : user.attributes.details.displayName;
    
    NSString *message;
    NSString *timeStamp;// = [NSDate mysqlDatetimeFormattedAsTimeAgo:@"2018-12-05 19:22:44"];
    
    switch (notificationType) {
        case NotificationTypeUserNewFollower:
            message = @"started following you";
            timeStamp = @"Now";
            break;
        case NotificationTypeRoomJoinRequest: {
            NSString *roomName = @"Pinball Fanatics";
            message = [NSString stringWithFormat:@"requested to join %@", roomName];
            timeStamp = @"15m";
            break;
        }
        case NotificationTypeRoomNewMember: {
            NSString *roomName = @"WA Alums";
            message = [NSString stringWithFormat:@"joined %@", roomName];
            timeStamp = @"1h";
            break;
        }
        case NotificationTypeRoomApprovedRequest: {
            NSString *roomName = @"Team Bonfire";
            message = [NSString stringWithFormat:@"approved your request to join %@", roomName];
            timeStamp = @"2h";
            break;
        }
        case NotificationTypePostReply:
            message = @"replied to your post";
            timeStamp = @"3h";
            break;
        case NotificationTypePostSparks: {
            NSInteger sparks = 350;
            message = [NSString stringWithFormat:@"and %ld %@ sparked your post", (long)sparks, (sparks == 1 ? @"other" : @"others")];
            timeStamp = @"3h";
            break;
        }
            
            
        default:
            break;
    }
    
    NSString *baseString = [NSString stringWithFormat:@"%@ %@. %@", displayName, message, timeStamp];
    
    NSMutableAttributedString *combinedString = [[NSMutableAttributedString alloc] initWithString:baseString];
    [combinedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:14.f weight:UIFontWeightBold] range:NSMakeRange(0, displayName.length)];
    [combinedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:14.f weight:UIFontWeightRegular] range:NSMakeRange(displayName.length, combinedString.length - displayName.length)];
    
    [combinedString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithWhite:0.2f alpha:1] range:NSMakeRange(0, combinedString.length - timeStamp.length)];
    [combinedString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithWhite:0.6f alpha:1] range:NSMakeRange(combinedString.length - timeStamp.length, timeStamp.length)];
    
    return combinedString;
}

@end
