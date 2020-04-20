//
//  BFComponent.h
//  Pulse
//
//  Created by Austin Valleskey on 1/19/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BFJSONModel.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class BFComponent;
@class BFComponentSettings;

@protocol BFComponent;

@protocol BFComponentProtocol <NSObject>

@required
+ (CGFloat)heightForComponent:(BFComponent *)component;

@end

@interface BFComponent : BFJSONModel

typedef enum {
    BFComponentDetailLevelAll, // include context
    BFComponentDetailLevelSome, // no context
    BFComponentDetailLevelMinimum // no actions, no context
} BFComponentDetailLevel;

- (id)initWithSettings:(BFComponentSettings * _Nullable)settings className:(NSString *)className detailLevel:(BFComponentDetailLevel)detailLevel;

- (void)updateCellHeight;

// This tells the table view what kind of cell to render
@property (nonatomic) NSString *className;
- (Class _Nullable)cellClass;

@property (nonatomic) BFComponentSettings <Optional> *settings;
@property (nonatomic) CGFloat cellHeight;
@property (nonatomic) BFComponentDetailLevel detailLevel;
@property (nonatomic) BOOL showLineSeparator;
@property (nonatomic, copy) void (^_Nullable action)(void);

@end

@interface BFComponentSettings : BFJSONModel

@property (nonatomic) NSInteger number;
@property (nonatomic) UIColor <Optional> *color;
@property (nonatomic) NSString <Optional> *title;
@property (nonatomic) NSString <Optional> *text;

@end

NS_ASSUME_NONNULL_END
