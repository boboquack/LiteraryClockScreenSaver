//
//  LiteraryClockScreenSaverView.h
//  LiteraryClockScreenSaver
//
//  Created by Mike Mattozzi on 8/5/18.
//  Copyright © 2018 Mike Mattozzi. All rights reserved.
//

#import <ScreenSaver/ScreenSaver.h>

@interface LiteraryClockScreenSaverView : ScreenSaverView {
    NSImage* libraryImage1;
    CGFloat backgroundImageX;
    NSRect backgroundImageRect;
}

@property (retain) NSMutableDictionary *timeToQuote;
@property NSInteger fileLength;
@property (retain) NSString* resourcePath;
@property CGFloat lastY;


@end
