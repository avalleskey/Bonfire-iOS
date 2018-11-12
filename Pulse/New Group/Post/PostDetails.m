#import "PostDetails.h"

@implementation PostDetails

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

- (NSString *)simpleMessage {
    NSString *trimmedString = [self trimString:self.message];
    
    return trimmedString;
    
    
    // TODO: Disabled for now - still need to build metadata downloader
    
    // trim leading and trailing spaces
    if (self.message != nil) {
        NSString *trimmedString = [self trimString:self.message];        
        // break apart the message
        // Only TRUE if:
        // • begins or ends with valid URL
        // • has only one URL
        
        NSArray *parts = [trimmedString componentsSeparatedByString:@" "];
        if (parts.count > 0) {
            NSString *firstPart = [parts firstObject];
            
            if ([self validateUrl:firstPart]) {
                NSLog(@"found valid URL: %@", firstPart);
                return [trimmedString stringByReplacingCharactersInRange:NSMakeRange(0, firstPart.length + 1) withString:@""];
            }
            else if (parts.count > 1 &&
                     [self validateUrl:[parts lastObject]]) {
                NSString *lastPart = [parts lastObject];
                
                NSLog(@"found valid URL at end: %@", lastPart);
                return [self trimString:[trimmedString stringByReplacingCharactersInRange:[trimmedString rangeOfString:lastPart] withString:@""]];
            }
        }
    }
    
    return self.message;
}

- (NSString *)trimString:(NSString *)string {
    if (string != nil) {
        return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    
    return @"";
}

- (BOOL)validateUrl: (NSString *) candidate {
    NSString *urlRegEx =
    @"(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+";
    NSPredicate *urlTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", urlRegEx];
    return [urlTest evaluateWithObject:candidate];
}

@end

