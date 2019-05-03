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
#import "NSDate+NVTimeAgo.h"

@implementation NSAttributedString (NotificationConveniences)

+ (NSAttributedString *)attributedStringForActivity:(UserActivity *)activity {
    User *user = [Session sharedInstance].currentUser;
    NSString *message;
    NSString *timeStamp = [NSDate mysqlDatetimeFormattedAsTimeAgo:activity.attributes.status.createdAt withForm:TimeAgoShortForm];
    
    /*
    if (activity.type == USER_ACTIVITY_TYPE_USER_FOLLOW) {
        user = activity.attributes.details.followedBy;
        message = @"started following you";
    }
    else if (activity.type == USER_ACTIVITY_TYPE_USER_ACCEPTED_ACCESS) {
        user = activity.attributes.details.acceptedBy;
        NSString *roomName = activity.attributes.details.room.attributes.details.title;
        message = [NSString stringWithFormat:@"approved your request to join %@", roomName];
    }
    else if (activity.type == USER_ACTIVITY_TYPE_ROOM_ACCESS_REQUEST) {
        user = activity.attributes.details.requestedBy;
        NSString *roomName = activity.attributes.details.room.attributes.details.title;
        message = [NSString stringWithFormat:@"requested to join %@", roomName];
    }
    else if (activity.type == USER_ACTIVITY_TYPE_POST_REPLY) {
        user = activity.attributes.details.repliedBy;
        message = @"replied to your post";
    }
    else if (activity.type == USER_ACTIVITY_TYPE_POST_SPARKED) {
        user = activity.attributes.details.sparkedBy;
        message = @"sparked your post";
        // message = [NSString stringWithFormat:@"and %ld %@ sparked your post", (long)sparks, (sparks == 1 ? @"other" : @"others")];
    }
    else if (activity.type == USER_ACTIVITY_TYPE_USER_POSTED) {
        // TODO: Create user posted icon/color combo
    }
    else {
        // unknown
        message = @"";
        timeStamp = @"";
    }
     */
    
    /*case NotificationTypeRoomNewMember: {
        NSString *roomName = @"WA Alums";
        message = [NSString stringWithFormat:@"joined %@", roomName];
        timeStamp = @"1h";
        break;
    }*/
    
    NSString *username = user.attributes.details.identifier == nil ? @"anonymous" : [NSString stringWithFormat:@"@%@", user.attributes.details.identifier];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:username];
    // UIFont *heavyItalicFont = [UIFont fontWithDescriptor:[[[UIFont systemFontOfSize:15.f weight:UIFontWeightHeavy] fontDescriptor] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic] size:15.f];
    [attributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:15.f weight:UIFontWeightSemibold] range:NSMakeRange(0, attributedString.length)];
    [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor bonfireBlack] range:NSMakeRange(0, attributedString.length)];
    
    NSString *baseString = [NSString stringWithFormat:@" %@. %@", message, timeStamp];
    
    NSMutableAttributedString *detailsString = [[NSMutableAttributedString alloc] initWithString:baseString];
    [detailsString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:15.f weight:UIFontWeightRegular] range:NSMakeRange(0, detailsString.length)];
    [detailsString addAttribute:NSForegroundColorAttributeName value:[UIColor bonfireBlack] range:NSMakeRange(0, detailsString.length - timeStamp.length)];
    [detailsString addAttribute:NSForegroundColorAttributeName value:[UIColor bonfireGray] range:NSMakeRange(baseString.length - timeStamp.length, timeStamp.length)];
    
    [attributedString appendAttributedString:detailsString];
    
    return attributedString;
}

@end
