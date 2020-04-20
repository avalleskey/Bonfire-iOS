//
//  BFJSONModel.h
//  Pulse
//
//  Created by Austin Valleskey on 11/14/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "JSONModel.h"
#import "NSNull+JSON.h"
#import "NSDictionary+JSON.h"

NS_ASSUME_NONNULL_BEGIN

@interface BFJSONModel : JSONModel

@end

@interface JSONValueTransformer (NSAttributedString)

- (NSAttributedString *)NSAttributedStringFromNSString:(NSString *)string;
- (NSString *)JSONObjectFromNSAttributedString:(NSAttributedString *)string;

@end

NS_ASSUME_NONNULL_END
