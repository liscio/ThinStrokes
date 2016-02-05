//
//  ThinStrokes.h
//  ThinStrokes
//
//  Created by Christopher Liscio on 2016-02-04.
//  Copyright © 2016 SuperMegaUltraGroovy, Inc. All rights reserved.
//

#import <AppKit/AppKit.h>

@class ThinStrokes;

static ThinStrokes *sharedPlugin;

@interface ThinStrokes : NSObject

+ (instancetype)sharedPlugin;
- (id)initWithBundle:(NSBundle *)plugin;

@property (nonatomic, strong, readonly) NSBundle* bundle;
@end