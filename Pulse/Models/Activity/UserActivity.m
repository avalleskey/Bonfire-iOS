//
//  UserActivity.m
//  Pulse
//
//  Created by Austin Valleskey on 3/8/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "UserActivity.h"
#import "Session.h"
#import "UIColor+Palette.h"
#import "NSDate+NVTimeAgo.h"
#import "GTMNSString+HTML.h"

@implementation UserActivity

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"identifier": @"id"
                                                                  }];
}

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError **)err {
    UserActivity *instance = [super initWithDictionary:dict error:err];
    instance.attributes.attributedString = [instance createAttributedString];
        
    return instance;
}

- (NSAttributedString *)createAttributedString {
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
    
    CGFloat fontSize = 15.f;
    
    // available variables
    NSMutableDictionary *variables = [[NSMutableDictionary alloc] init];
    if (self.attributes.actioner.attributes.identifier) {
        [variables setObject:[NSString stringWithFormat:@"@%@", self.attributes.actioner.attributes.identifier] forKey:@"$actioner.username"];
    }
    if (self.attributes.actioner.attributes.displayName) {
        [variables setObject:self.attributes.actioner.attributes.displayName forKey:@"$actioner.displayName"];
    }
    if (self.attributes.actioner.attributes.bio) {
        [variables setObject:self.attributes.actioner.attributes.bio forKey:@"$actioner.bio"];
    }
    if (self.attributes.camp.attributes.title) {
        [variables setObject:self.attributes.camp.attributes.title forKey:@"$camp.title"];
    }
    else if (self.attributes.post.attributes.postedIn.attributes.title) {
        [variables setObject:self.attributes.post.attributes.postedIn.attributes.title forKey:@"$camp.title"];
    }
    if (self.attributes.camp.attributes.theDescription) {
        [variables setObject:self.attributes.camp.attributes.theDescription forKey:@"$camp.description"];
    }
    if (self.attributes.camp.attributes.identifier) {
        [variables setObject:[NSString stringWithFormat:@"#%@", self.attributes.camp.attributes.identifier] forKey:@"$camp.identifier"];
    }
    if (self.attributes.post.attributes.message) {
        [variables setObject:self.attributes.post.attributes.message forKey:@"$post.message"];
    }
    
    NSArray *stringParts = @[];
    
    NSDictionary *formats = [Session sharedInstance].defaults.notifications;
    
    NSString *key = [NSString stringWithFormat:@"%u", self.attributes.type];
    
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
        }
        else {
            attributedPart = [[NSMutableAttributedString alloc] initWithString:part attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:fontSize weight:UIFontWeightRegular], NSForegroundColorAttributeName: [UIColor bonfirePrimaryColor]}];
        }
        
        [attributedString appendAttributedString:attributedPart];
    }
    
    NSString *timeStamp = self.attributes.createdAt.length > 0 ? [NSDate mysqlDatetimeFormattedAsTimeAgo:self.attributes.createdAt withForm:TimeAgoShortForm] : @"";

    NSMutableAttributedString *timeStampString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@", timeStamp]];
    [timeStampString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:fontSize weight:UIFontWeightRegular] range:NSMakeRange(0, timeStampString.length)];
    [timeStampString addAttribute:NSForegroundColorAttributeName value:[UIColor bonfireGrayWithLevel:700] range:NSMakeRange(0, timeStampString.length)];
    [attributedString appendAttributedString:timeStampString];
    
    if ((self.attributes.post.attributes.message.length > 0 && !self.attributes.replyPost) || self.attributes.replyPost.attributes.message.length > 0) {
        NSString *message = self.attributes.replyPost.attributes.message ? self.attributes.replyPost.attributes.message : self.attributes.post.attributes.message;

        // define the range you're interested in
        NSRange stringRange = {0, MIN([message length], 40)};

        // adjust the range to include dependent chars
        stringRange = [message rangeOfComposedCharacterSequencesForRange:stringRange];

        // Now you can create the short string
        NSString *shortenedMessage = [message substringWithRange:stringRange];
        if (shortenedMessage.length < message.length) {
            message = [[shortenedMessage stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByAppendingString:@"..."];
        }
        
        NSMutableAttributedString *messageString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@", message]];
        [messageString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:fontSize-1.f weight:UIFontWeightRegular] range:NSMakeRange(0, messageString.length)];
        [messageString addAttribute:NSForegroundColorAttributeName value:[UIColor bonfireSecondaryColor] range:NSMakeRange(0, messageString.length)];
        [attributedString appendAttributedString:messageString];
    }
    
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineSpacing:3.5];
    [attributedString addAttribute:NSParagraphStyleAttributeName
                             value:style
                             range:NSMakeRange(0, attributedString.string.length)];
    
    return attributedString;
}

- (void)updateAttributedString {
    self.attributes.attributedString = [self createAttributedString];
}

+ (BOOL)propertyIsOptional:(NSString*)propertyName
{
    return YES;
}

- (void)markAsRead {
    self.attributes.read = true;
}

@end

@implementation UserActivityAttributes

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

+ (BOOL)propertyIsOptional:(NSString*)propertyName
{
    return YES;
}

@end

@implementation JSONValueTransformer (NSAttributedString)

- (NSAttributedString *)NSAttributedStringFromNSString:(NSString *)string {
    NSData* data = [string dataUsingEncoding:NSUTF8StringEncoding];
    
    NSAttributedString *attrString = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        
    return attrString; // transformed object
}

- (NSString *)JSONObjectFromNSAttributedString:(NSAttributedString *)string {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:string];

    NSString *convertedStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    return convertedStr; // transformed object
}

@end
