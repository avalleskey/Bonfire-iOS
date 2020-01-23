//
//  SectionStream.h
//  Pulse
//
//  Created by Austin Valleskey on 12/6/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "Post.h"
#import "GenericStream.h"
#import "BFComponent.h"
#import "Post.h"
#import "Section.h"

NS_ASSUME_NONNULL_BEGIN

@class SectionStream;
@class SectionStreamPage;

@protocol SectionStreamDelegate <NSObject>

- (void)sectionStreamDidUpdate:(SectionStream *)stream;

@end

@interface SectionStream : GenericStream <NSCoding>

@property (nonatomic, weak) id <SectionStreamDelegate> delegate;

@property (nonatomic, strong) NSMutableArray <SectionStreamPage *> *pages;
@property (nonatomic, strong) NSMutableArray <Section *> *sections;
- (void)flush;

@property (nonatomic) NSString *prevCursor;
@property (nonatomic) NSString *nextCursor;

- (void)prependPage:(SectionStreamPage *)page;
- (void)appendPage:(SectionStreamPage *)page;

- (Post *)postWithId:(NSString *)postId;

@property (nonatomic) BFComponentDetailLevel detailLevel;

typedef enum {
    SectionStreamEventTypeUnknown,
    
    SectionStreamEventTypeSectionUpdated,
    SectionStreamEventTypeSectionRemoved,
    
    SectionStreamEventTypePostUpdated,
    SectionStreamEventTypePostRemoved,
    
    SectionStreamEventTypeCampUpdated,
    
    SectionStreamEventTypeUserUpdated,
} SectionStreamEventType;
- (BOOL)performEventType:(SectionStreamEventType)eventType object:(id)object;

@end

@interface SectionStreamPage : BFJSONModel

@property (nonatomic) NSArray<Section *><Section> *data;
@property (nonatomic) GenericStreamPageMeta <Optional> *meta;

@end

NS_ASSUME_NONNULL_END
