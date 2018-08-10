//
//  LiteraryClockScreenSaverView.m
//  LiteraryClockScreenSaver
//
//  Created by Mike Mattozzi on 8/5/18.
//  Copyright © 2018 Mike Mattozzi. All rights reserved.
//

#import "LiteraryClockScreenSaverView.h"
#import "HighlightedQuote.h"

@implementation LiteraryClockScreenSaverView

@synthesize timeToQuote;
@synthesize fileLength;
@synthesize resourcePath;

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self setAnimationTimeInterval:1/30.0];
    }
    
    backgroundImageIndex = 0;
    backgroundImageList = [[NSMutableArray alloc] init];
    
    for (int i = 1; i <= 3; i++) {
        NSString *fileName = [NSString stringWithFormat:@"library%d", i];
        NSLog(@"Loading image %@", fileName);
        NSString *pathOfLibraryImage = [[NSBundle bundleForClass:[self class]] pathForResource:fileName ofType:@"jpg"];
        NSImage* libraryImage = [[NSImage alloc] initWithContentsOfFile:pathOfLibraryImage];
        [backgroundImageList addObject:libraryImage];
    }
    
    NSString* timeFormat = @"^\\d\\d:\\d\\d";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^\\d\\d"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    
    textPositionY = 200.0;
    backgroundImageRect = self.bounds;
    backgroundImageRect.size.height = backgroundImageRect.size.height*1.2;
    backgroundImageRect.size.width = backgroundImageRect.size.width*1.2;
    backgroundImageRect.origin.x = 0 - (backgroundImageRect.size.width - self.bounds.size.width);
    
    timeToQuote = [[NSMutableDictionary alloc] init];
    
    NSString *pathOfQuoteFile = [[NSBundle bundleForClass:[self class]] pathForResource:@"litclock_annotated" ofType:@"csv"];
    
    fileLength = 0;
    resourcePath = pathOfQuoteFile;
    
    NSString* fileContents = [NSString stringWithContentsOfFile:pathOfQuoteFile encoding:NSUTF8StringEncoding error:nil];
    
    fileLength = [fileContents length];
    
    NSArray* rows = [fileContents componentsSeparatedByString:@"\n"];
    for (NSString *row in rows){
        NSUInteger numberOfMatches = [regex numberOfMatchesInString:row
                                                            options:0
                                                              range:NSMakeRange(0, [row length])];
        if (numberOfMatches > 0) {
            NSArray* columns = [row componentsSeparatedByString:@"|"];
            if ([columns count] == 5) {
                HighlightedQuote *highlightedQuote = [HighlightedQuote initWithQuote:columns[2] author:columns[4] book:columns[3] timeString:columns[1]];
                [timeToQuote setObject:highlightedQuote forKey:columns[0]];
            } else {
                NSLog(@"%@ does not seem formatted correctly; not enough columns.", row);
            }
        } else {
            NSLog(@"%@ does not seem formatted correctly.", row);
        }
    }
    
    NSLog(@"Done loading quotes. %ld quotes stored.", [timeToQuote count]);
    
    return self;
}

- (void)startAnimation
{
    [super startAnimation];
}

- (void)stopAnimation
{
    [super stopAnimation];
}

- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];
}

- (void)animateOneFrame
{
    NSDate* now = [NSDate date];
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *dateComponents = [gregorian components:(NSHourCalendarUnit  | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:now];
    NSInteger hour = [dateComponents hour];
    NSInteger minute = [dateComponents minute];
    
    NSString *paddedHour = [NSString stringWithFormat:@"%02ld", hour];
    NSString *paddedMinute = [NSString stringWithFormat:@"%02ld", minute];
    NSString *formattedTime = [NSString stringWithFormat:@"%@:%@", paddedHour, paddedMinute];
    
    // Good test time
    // NSString *formattedTime = @"23:31";
    
    [[NSColor blackColor] setFill];
    NSRectFill(self.bounds);
    [[NSColor lightGrayColor] set];
    
    backgroundImageRect.origin.x += 0.25;
    if (backgroundImageRect.origin.x > 0) {
        backgroundImageRect.origin.x = 0 - (backgroundImageRect.size.width - self.bounds.size.width);
        backgroundImageIndex += 1;
        backgroundImageIndex = backgroundImageIndex % [backgroundImageList count];
    }
    NSLog(@"Using background image: %ld", backgroundImageIndex);
    [(NSImage*)[backgroundImageList objectAtIndex:backgroundImageIndex] drawInRect:backgroundImageRect];
    
    HighlightedQuote *timeQuote = [timeToQuote valueForKey:formattedTime];
    if (textPositionY > self.bounds.size.height) {
        textPositionY = -200.0;
    }
    NSRect quoteRect = self.bounds;
    quoteRect.origin.y = textPositionY;
    quoteRect.origin.x = 100.0;
    quoteRect.size.width = quoteRect.size.width - 200.0;
    quoteRect.size.height = 200.0;
    
    NSFont* font = [NSFont fontWithName:@"Lucida Grande" size:36.0];
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    NSFont *boldFontName = [fontManager fontWithFamily:@"Lucida Grande" traits:NSBoldFontMask weight:0 size:48.0];
    
    if (timeQuote) {
        NSMutableAttributedString *highlightedString = [[NSMutableAttributedString alloc] initWithString:timeQuote.quote];
        NSRange fullStringRange = NSMakeRange(0, [highlightedString length]);
        [highlightedString beginEditing];
        [highlightedString addAttribute:NSForegroundColorAttributeName value:[NSColor whiteColor] range:fullStringRange];
        NSShadow *shadow = [[NSShadow alloc] init];
        shadow.shadowOffset = NSMakeSize(-5, -5);
        shadow.shadowColor = [NSColor colorWithSRGBRed:0.0 green:0.0 blue:0.0 alpha:0.75];
        [highlightedString addAttribute:NSShadowAttributeName value:shadow range:fullStringRange];
        [highlightedString addAttribute:NSFontAttributeName value:font range:fullStringRange];
        [highlightedString addAttribute:NSFontAttributeName value:boldFontName range:[timeQuote rangeOfHighlight]];
        [highlightedString endEditing];
        
        [highlightedString drawInRect:quoteRect];
    } else {
        [formattedTime drawInRect:quoteRect withAttributes:@{
                                                             NSForegroundColorAttributeName: [NSColor whiteColor],
                                                             NSFontAttributeName: font
                                                             }];
    }
    
    // Scroll bottom to top, slowly
    textPositionY = textPositionY + 0.5;
    
    // Debug string
    /*
    NSString *infoString = [NSString stringWithFormat:@"Path: %@, File length: %ld, Quote count: %ld, Time string: %@", resourcePath, fileLength, [timeToQuote count], formattedTime];
    [infoString drawAtPoint:NSMakePoint(100.0, 100.0) withAttributes:@{
                                                                       NSForegroundColorAttributeName: [NSColor lightGrayColor]
                                                                       }];
     */
}

- (BOOL)hasConfigureSheet
{
    return NO;
}

- (NSWindow*)configureSheet
{
    return nil;
}

@end
