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
#import "NSString+UTF.h"

@implementation UserActivity

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"identifier": @"id"
                                                                  }];
}

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError **)err {
    UserActivity *instance = [super initWithDictionary:dict error:err];
    
    // set preview post before anything else
    if (self.attributes.target &&
        self.attributes.target.object &&
        [self.attributes.target.object isKindOfClass:[Post class]]) {
        instance.attributes.previewPost = (Post *)self.attributes.target.object;
    }
    else if (self.attributes.replyPost) {
        instance.attributes.previewPost = self.attributes.replyPost;
    }
    else if (self.attributes.post) {
        instance.attributes.previewPost = self.attributes.post;
    }
    
    instance.attributes.attributedString = [instance createAttributedString];
        
    instance.attributes.includeUserAttachment = self.attributes.type == USER_ACTIVITY_TYPE_USER_FOLLOW;// && (self.attributes.actioner.attributes.bio.length > 0 || self.attributes.actioner.attributes.location.displayText.length > 0 || self.attributes.actioner.attributes.website.displayUrl.length > 0);
    instance.attributes.includeCampAttachment = (self.attributes.type == USER_ACTIVITY_TYPE_USER_ACCEPTED_ACCESS);
    
    return instance;
}

- (NSAttributedString *)createAttributedString {
    CGFloat fontSize = 15.f;
    NSString *title = self.attributes.title.title.length == 0 ? @"" : self.attributes.title.title;

    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:title attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:fontSize weight:UIFontWeightRegular], NSForegroundColorAttributeName: [UIColor bonfirePrimaryColor]}];
    
    if (self.attributes && self.attributes.title && title.length > 0 && self.attributes.title.entities) {
        for (UserActivityEntity *entity in self.attributes.title.entities) {
            NSArray *indices = entity.indices;

            if (indices.count == 2) {
                NSInteger loc1 = [indices[0] integerValue];
                NSInteger len1 = [indices[1] integerValue] - [entity.indices[0] integerValue];
                
                if (len1 > 0) {
                    NSRange range = [title composedRangeWithRange:NSMakeRange(loc1, len1)];
                    NSInteger endSpot = range.location + range.length;

                    if (endSpot > range.location && endSpot <= title.length && range.location >= 0) {
                        [attributedString addAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:fontSize weight:UIFontWeightSemibold], NSForegroundColorAttributeName: [UIColor bonfirePrimaryColor]} range:range];
                    }
                }
            }
        }
    }
    
    NSString *timeStamp = self.attributes.createdAt.length > 0 ? [NSDate mysqlDatetimeFormattedAsTimeAgo:self.attributes.createdAt withForm:TimeAgoShortForm] : @"";
    
    NSMutableAttributedString *timeStampString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@", timeStamp]];
    [timeStampString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:fontSize weight:UIFontWeightRegular] range:NSMakeRange(0, timeStampString.length)];
    [timeStampString addAttribute:NSForegroundColorAttributeName value:[UIColor bonfireSecondaryColor] range:NSMakeRange(0, timeStampString.length)];
    [attributedString appendAttributedString:timeStampString];
    
    if (self.attributes.previewPost.attributes.message.length > 0) {
        NSString *message = self.attributes.previewPost.attributes.message;

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

@implementation UserActivityAttributesTitle

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

+ (BOOL)propertyIsOptional:(NSString*)propertyName
{
    return YES;
}

@end

@implementation UserActivityEntity

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

+ (BOOL)propertyIsOptional:(NSString*)propertyName
{
    return YES;
}

@end

@implementation UserActivityAttributesTarget

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError **)err {
    UserActivityAttributesTarget *instance = [super initWithDictionary:dict error:err];
    
    if ([self.object isKindOfClass:[NSDictionary class]] && [(NSDictionary *)self.object objectForKey:@"type"]) {
        NSDictionary *dict = (NSDictionary *)self.object;
        NSString *type = [dict objectForKey:@"type"];
        if ([type isEqualToString:@"camp"]) {
            self.object = [[Camp alloc] initWithDictionary:dict error:nil];
        }
        else if ([type isEqualToString:@"post"]) {
            self.object = [[Post alloc] initWithDictionary:dict error:nil];
        }
        else if ([type isEqualToString:@"user"]) {
            self.object = [[User alloc] initWithDictionary:dict error:nil];
        }
        else if ([type isEqualToString:@"bot"]) {
            self.object = [[Bot alloc] initWithDictionary:dict error:nil];
        }
    }
    
    return instance;
}

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
