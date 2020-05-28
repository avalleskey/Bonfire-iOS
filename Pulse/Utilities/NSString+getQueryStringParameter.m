#import <Foundation/Foundation.h>

#import "NSString+getQueryStringParameter.h"

@implementation NSURL (getQueryStringParameter)

- (NSString *)getQueryString {
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:self
                                                resolvingAgainstBaseURL:NO];
    NSArray *queryItems = urlComponents.queryItems;
    
    if ([queryItems count] == 0) return @"";
    
    NSString *string = @"";
    for (NSURLQueryItem *item in queryItems) {
        string = [string stringByAppendingFormat:@"%@=%@%@", item.name, item.value, (item != [queryItems lastObject] ? @"&" : @"")];
    }
    NSLog(@"string:: %@", string);
    
    return string;
}

@end
