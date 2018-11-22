#import "Post.h"

@implementation Post

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                                                                  @"identifier": @"id"
                                                                  }];
}

- (BOOL)requiresURLPreview {
    return false;
    
    /*
    if (self.attributes.details.message != nil) {
        // break apart the message
        // Only TRUE if:
        // • begins or ends with valid URL
        // • has only one URL
        
        NSArray *parts = [self.attributes.details.message componentsSeparatedByString:@" "];
        if (parts.count > 0) {
            if ([self validateUrl:[parts firstObject]]) {
                NSLog(@"found valid URL: %@", [parts firstObject]);
                return true;
            }
            else if (parts.count > 1 &&
                     [self validateUrl:[parts lastObject]]) {
                NSLog(@"found valid URL at end: %@", [parts lastObject]);
                return true;
            }
        }
    }
    
    return false;*/
}

- (BOOL)validateUrl: (NSString *) candidate {
    NSString *urlRegEx =
    @"(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+";
    NSPredicate *urlTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", urlRegEx];
    return [urlTest evaluateWithObject:candidate];
}

@end

