//
//  BFComponent.m
//  Pulse
//
//  Created by Austin Valleskey on 1/19/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import "BFComponent.h"
#import "StreamPostCell.h"

@implementation BFComponent

- (id)initWithObject:(id _Nullable)object className:(NSString *)className detailLevel:(BFComponentDetailLevel)detailLevel {
    if (self = [super init]) {
        if (object) {
            self.object = object;
        }
                
        self.className = className;
        self.detailLevel = detailLevel;
        
        [self updateCellHeight];
    }
    
    return self;
}

+ (BOOL)propertyIsOptional:(NSString*)propertyName
{

    return YES;
}

- (Class _Nullable)cellClass {
    if (!self.className) return nil;
    
    return NSClassFromString(self.className);
}

//- (id)initWithCoder:(NSCoder *)decoder {
//  if (self = [super init]) {
//      self.cellClass = [decoder decodeObjectForKey:@"cellClass"];
//      self.object = [decoder decodeObjectForKey:@"object"];
//      self.cellHeight = [decoder decodeFloatForKey:@"cellHeight"];
//      self.detailLevel = (BFComponentDetailLevel)[decoder decodeObjectForKey:@"detailLevel"];
//      self.showLineSeparator = [decoder decodeBoolForKey:@"showLineSeparator"];
//      self.action = [decoder decodeObjectForKey:@"action"];
//  }
//  return self;
//}
//
//- (void)encodeWithCoder:(NSCoder *)encoder {
//    [encoder encodeObject:_cellClass forKey:@"cellClass"];
//    [encoder encodeObject:_object forKey:@"object"];
//    [encoder encodeFloat:_cellHeight forKey:@"cellHeight"];
//    [encoder encodeObject:[NSNumber numberWithInteger:_detailLevel] forKey:@"detailLevel"];
//    [encoder encodeBool:_showLineSeparator forKey:@"showLineSeparator"];
//    [encoder encodeObject:_action forKey:@"action"];
//}


#pragma mark - NSCopying
- (id)copyWithZone:(NSZone *)zone
{
    BFComponent *copyObject = [[BFComponent alloc] initWithObject:_object className:_className detailLevel:_detailLevel];
    
    copyObject.showLineSeparator = _showLineSeparator;
    copyObject.action = _action;

    return copyObject;
}

- (void)updateCellHeight {
    if ([self.className conformsToProtocol:@protocol(BFComponentProtocol)]) {
        NSInvocationOperation *invo = [[NSInvocationOperation alloc] initWithTarget:self.className selector:@selector(heightForComponent:) object:self];
        [invo start];
        CGFloat f = 0;
        [invo.result getValue:&f];
        
        self.cellHeight = f;
    }
    else {
        DLog(@"!!!! %@ does not conform to BFComponentProtocol", NSStringFromClass(self.className.class));
        self.cellHeight = 0;
    }
}

- (NSString *)description
{
    NSMutableString *string = [NSMutableString new];
    [string appendString:@"<BFComponent>"];
    
    if (self.className) {
        [string appendFormat:@"\n[cellClass]: %@", self.className];
    }
    
    return string;
}

@end
