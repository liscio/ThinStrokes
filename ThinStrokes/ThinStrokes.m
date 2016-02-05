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
#import "RTProtocol.h"
#import "MARTNSObject.h"
#import "RTMethod.h"

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
    
    [self replaceLayoutManagerForClass:NSClassFromString(@"DVTSourceTextView")];
}

static void ShowCGGlyphsButThinThisTime(id self, SEL _cmd, const CGGlyph *glyphs, const NSPoint *positions, NSUInteger count, NSFont *font, NSAffineTransform *matrix, NSDictionary *attributes, NSGraphicsContext *inContext) {

    CGContextRef ctx = [inContext CGContext];
    
    // The below code—save for the swizzling—is copied nearly verbatim from
    // iTerm. Here's the source: https://github.com/gnachman/iTerm2/blob/76fe643f505eb3a0eed5a8390c39325e3c22d179/sources/iTermTextDrawingHelper.m#L681
    
    int savedFontSmoothingStyle = 0;
    BOOL useThinStrokes = YES;
    if (useThinStrokes) {
        // This seems to be available at least on 10.8 and later. The only reference to it is in
        // WebKit. This causes text to render just a little lighter, which looks nicer.
        savedFontSmoothingStyle = CGContextGetFontSmoothingStyle(ctx);
        CGContextSetFontSmoothingStyle(ctx, 16);
    }
    
    CGContextSetTextDrawingMode(ctx, kCGTextFill);
    
    Class superclass = NSClassFromString(@"DVTLayoutManager");
    IMP superIMP = [superclass instanceMethodForSelector: @selector(showCGGlyphs:positions:count:font:matrix:attributes:inContext:)];

    ((void (*)(id, SEL, const CGGlyph *, const NSPoint *, NSUInteger, NSFont *, NSAffineTransform *, NSDictionary *, NSGraphicsContext *))superIMP)(self, _cmd, glyphs, positions, count, font, matrix, attributes, inContext);
    
    if (useThinStrokes) {
        CGContextSetFontSmoothingStyle(ctx, savedFontSmoothingStyle);
    }
}

// encapsulate code needed to override an existing method
static void Override(Class c, SEL sel, void *fptr) {
    RTMethod *superMethod = [[c superclass] rt_methodForSelector: sel];
    RTMethod *newMethod = [RTMethod methodWithSelector: sel implementation: fptr signature: [superMethod signature]];
    [c rt_addMethod: newMethod];
}

static Class createThinLayoutManager() {
    Class DVTLayoutManager = NSClassFromString(@"DVTLayoutManager");
    if(!DVTLayoutManager)
        return nil;
    
    Class c = [DVTLayoutManager rt_createSubclassNamed: @"ThinLayoutManager"];
    Override(c, @selector(showCGGlyphs:positions:count:font:matrix:attributes:inContext:), ShowCGGlyphsButThinThisTime);
    
    return c;
}

static Class ThinLayoutManager(void) {
    static Class c = nil;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        c = createThinLayoutManager();
    });
    
    return c;
}

- (void)replaceLayoutManagerForClass:(Class)clazz {
    SEL selector = @selector(layoutManager);
    Method m = class_getInstanceMethod(clazz, selector);
    IMP oldImplementation = method_getImplementation(m);
    IMP newImplementation = imp_implementationWithBlock((id)^(id SELF) {
        id oldLM = ((id (*)(id, SEL))oldImplementation)(SELF, selector);
        
        if (![oldLM isKindOfClass:ThinLayoutManager()]) {
            NSAssert([oldLM isKindOfClass:NSClassFromString(@"DVTLayoutManager")], @"Right?");
            
            [oldLM rt_setClass:ThinLayoutManager()];
        }
        
        return oldLM;
    });
    method_setImplementation(m, newImplementation);
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
