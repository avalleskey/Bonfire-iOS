//
//  Section.h
//  Pulse
//
//  Created by Austin Valleskey on 1/19/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import "BFJSONModel.h"
#import "BFComponent.h"

NS_ASSUME_NONNULL_BEGIN

@protocol Section;

@class Section;
@class SectionAttributes;
@class SectionAttributesCta;
@class SectionAttributesCtaTarget;

@interface Section : BFJSONModel

@property (nonatomic) NSString <Optional> *identifier;
@property (nonatomic) NSString <Optional> *type; // section
@property (nonatomic) SectionAttributes <Optional> *attributes;

// Array that contains the BFComponent objects created
// using the data provided in the section attributtes
@property (nonatomic, strong) NSMutableArray <BFComponent *> * _Nullable components;
- (void)refreshComponents;

@end

@interface SectionAttributes : BFJSONModel

@property (nonatomic) NSString <Optional> *title;
@property (nonatomic) NSString <Optional> *text;

@property (nonatomic) SectionAttributesCta <Optional> *cta;
@property (nonatomic) NSArray<Post *><Post, Optional> * _Nullable posts;

@end


@interface SectionAttributesCta : BFJSONModel

@property (nonatomic) NSString <Optional> *text;
@property (nonatomic) SectionAttributesCtaTarget <Optional> *target;

@end

@interface SectionAttributesCtaTarget : BFJSONModel

@property (nonatomic) Camp <Optional> *camp;

@end

NS_ASSUME_NONNULL_END
