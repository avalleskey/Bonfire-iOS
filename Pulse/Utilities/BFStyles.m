//
//  BFStyles.m
//  Pulse
//
//  Created by Austin Valleskey on 8/3/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFStyles.h"

@implementation UIView (BFStyles)

- (void)initStylesWithJSONFileNamed:(NSString *)fileName {
    self.styles = [[BFStyles alloc] initWithJSONFileNamed:fileName];
    [self run];
}
- (void)layoutSubviewsWithStyles {
    if (!self.styles) return;
    
    [self run];
}

@dynamic styles;
- (void)setStyles:(BFStyles *)styles {
    self.styles = styles;
}

- (void)run {
    for (BFStyleObject *style in self.styles) {
        NSLog(@"style:: %@", style);
    }
}

@end

@implementation BFStyles

- (instancetype)initWithJSONFileNamed:(NSString *)fileName {
    if (self = [super init]) {
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"json"];
        NSData *data = [NSData dataWithContentsOfFile:bundlePath];
        
        if (data) {
            NSArray *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            
            for (NSDictionary *item in json) {
                BFStyleObject *object = [[BFStyleObject alloc] initWithDictionary:item error:nil];
                [self addObject:object];
            }
        }
    }
    
    return self;
}

@end

@implementation BFStyleObject

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return true;
}

- (void)setPaddingTop:(float)paddingTop {
    if (paddingTop != _paddingTop) {
        _paddingTop = paddingTop;
        
        _padding.top = _paddingTop;
    }
}

- (void)setPaddingLeft:(float)paddingLeft {
    if (paddingLeft != _paddingLeft) {
        _paddingLeft = paddingLeft;
        
        _padding.left = _paddingLeft;
    }
}

- (void)setPaddingBottom:(float)paddingBottom {
    if (paddingBottom != _paddingBottom) {
        _paddingBottom = paddingBottom;
        
        _padding.bottom = _paddingBottom;
    }
}

- (void)setPaddingRight:(float)paddingRight {
    if (paddingRight != _paddingRight) {
        _paddingRight = paddingRight;
        
        _padding.right = _paddingRight;
    }
}

@end
