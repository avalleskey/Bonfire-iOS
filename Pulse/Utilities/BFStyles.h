//
//  BFStyles.h
//  Pulse
//
//  Created by Austin Valleskey on 8/3/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BFJSONModel.h"

NS_ASSUME_NONNULL_BEGIN

@class BFStyles;
@class BFStyleObject;

@interface UIView (BFStyles)

@property (nonatomic, strong) BFStyles *styles;

- (void)initStylesWithJSONFileNamed:(NSString *)fileName;
- (void)layoutSubviewsWithStyles;

@end

@interface BFStyles : NSMutableArray <BFStyleObject *>

- (instancetype)initWithJSONFileNamed:(NSString *)fileName;

@end

@interface BFStyleObject : BFJSONModel

@property (nonatomic) NSString *element;

@property (nonatomic) float width;
@property (nonatomic) float height;

@property (nonatomic) UIEdgeInsets padding;
@property (nonatomic) float paddingTop;
@property (nonatomic) float paddingLeft;
@property (nonatomic) float paddingBottom;
@property (nonatomic) float paddingRight;

@end

NS_ASSUME_NONNULL_END
