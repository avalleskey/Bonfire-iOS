//
//  BFJSONModel.m
//  Pulse
//
//  Created by Austin Valleskey on 11/14/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFJSONModel.h"

@implementation BFJSONModel

-(id)initWithDictionary:(NSDictionary*)dict error:(NSError**)err
{
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    return [super initWithDictionary:dict error:err];
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
