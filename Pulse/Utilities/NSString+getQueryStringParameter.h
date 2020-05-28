#import <Foundation/Foundation.h>

@interface NSURL (getQueryStringParameter)

/**
 * @method getQueryStringParameter:url:key
 * @abstract Method get specific value from NSURL
 *
 * I wrote this method follow these guides:
 * - https://gist.github.com/gillesdemey/509bb8a1a8c576ea215a
 * - https://stackoverflow.com/questions/8756683/best-way-to-parse-url-string-to-get-values-for-keys/26406426#26406426
 *
 */
- (NSString *)getQueryString;

@end
