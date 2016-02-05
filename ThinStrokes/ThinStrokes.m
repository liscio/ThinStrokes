//
//  ThinStrokes.m
//  ThinStrokes
//
//  Created by Christopher Liscio on 2016-02-04.
//  Copyright © 2016 Christopher Liscio, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import "ThinStrokes.h"

extern void CGContextSetFontSmoothingStyle(CGContextRef, int);
extern int CGContextGetFontSmoothingStyle(CGContextRef);

@interface ThinStrokes()

@property(nonatomic, strong, readwrite) NSBundle *bundle;
@property(nonatomic, assign, readwrite) BOOL useThinStrokes;
@end

@implementation ThinStrokes

+ (instancetype)sharedPlugin {
    return sharedPlugin;
}

- (id)initWithBundle:(NSBundle *)plugin
{
    if (self = [super init]) {
        self.useThinStrokes = YES;
        
        // reference to plugin's bundle, for resource access
        self.bundle = plugin;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didApplicationFinishLaunchingNotification:)
                                                     name:NSApplicationDidFinishLaunchingNotification
                                                   object:nil];
    }
    return self;
}

- (void)didApplicationFinishLaunchingNotification:(NSNotification*)noti {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidFinishLaunchingNotification object:nil];
    
    [self replaceGlyphsStuffForClass:NSClassFromString(@"NSLayoutManager")];
}

- (void)replaceGlyphsStuffForClass:(Class)clazz {
    SEL selector = @selector(showCGGlyphs:positions:count:font:matrix:attributes:inContext:);
    Method m = class_getInstanceMethod(clazz, selector);
    IMP oldImplementation = method_getImplementation(m);
    IMP newImplementation = imp_implementationWithBlock(^(id SELF, const CGGlyph *glyphs, const NSPoint *positions, NSUInteger count, NSFont *font, NSAffineTransform *matrix, NSDictionary *attributes, NSGraphicsContext *inContext) {
    
        CGContextRef ctx = [inContext CGContext];
        
        int savedFontSmoothingStyle = 0;
        BOOL useThinStrokes = YES;
        if (useThinStrokes) {
            // This seems to be available at least on 10.8 and later. The only reference to it is in
            // WebKit. This causes text to render just a little lighter, which looks nicer.
            savedFontSmoothingStyle = CGContextGetFontSmoothingStyle(ctx);
            CGContextSetFontSmoothingStyle(ctx, 16);
        }
        
        CGContextSetTextDrawingMode(ctx, kCGTextFill);
        
        ((void (*)(id, SEL, const CGGlyph *, const NSPoint *, NSUInteger, NSFont *, NSAffineTransform *, NSDictionary *, NSGraphicsContext *))oldImplementation)(SELF, selector, glyphs, positions, count, font, matrix, attributes, inContext);
        
        if (useThinStrokes) {
            CGContextSetFontSmoothingStyle(ctx, savedFontSmoothingStyle);
        }
    });
    method_setImplementation(m, newImplementation);
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
