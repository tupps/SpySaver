//
//  SpySaverView.m
//  SpySaver
//
//  Created by Luke Tupper on 6/08/13.
//  Copyright (c) 2013 Luke Tupper. All rights reserved.
//

#import "SpySaverView.h"
#import <QTKit/QTKit.h>
#import "LTImagePicker.h"

@interface SpySaverView()

@property (nonatomic, strong) QTCaptureSession *captureSession;
@property (nonatomic, strong) QTCaptureMovieFileOutput *captureMovieFileOutput;
@property (nonatomic, strong) QTCaptureDeviceInput *captureDeviceInput;
@property (nonatomic) NSInteger userTriggers;

@property (nonatomic, strong) NSBitmapImageRep *screenShotImage;
@property (nonatomic, strong) NSBitmapImageRep *screenShotImage2;

@end

@implementation SpySaverView

- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self setAnimationTimeInterval:1/30.0];
        
        NSString *fileName = [[ScreenSaverDefaults defaultsForModuleWithName:@"com.tupps.SpySaver"] stringForKey:@"imageFileName"];
        NSLog(@"Trying to load: %@", fileName);
        self.screenShotImage = [NSBitmapImageRep imageRepWithData:[NSData dataWithContentsOfFile:fileName]];
        NSLog(@"Screenshot loaded: %@", self.screenShotImage);
        
        NSString *fileName2 = [[ScreenSaverDefaults defaultsForModuleWithName:@"com.tupps.SpySaver"] stringForKey:@"imageFileName2"];
        self.screenShotImage2 = [NSBitmapImageRep imageRepWithData:[NSData dataWithContentsOfFile:fileName2]];
    }
    return self;
}

-(void)updateConfigWindow:(NSWindow *)window usingDefaults:(ScreenSaverDefaults *)defaults {
	[self.imagePicker setFileName:[defaults stringForKey:@"imageFileName"]];
    NSImage *img = [[[NSImage alloc] initWithContentsOfFile:[self.imagePicker fileName]] autorelease];
    [self.imagePicker setImage:img];
    
    [self.imagePicker2 setFileName:[defaults stringForKey:@"imageFileName2"]];
    NSImage *img2 = [[[NSImage alloc] initWithContentsOfFile:[self.imagePicker2 fileName]] autorelease];
    [self.imagePicker2 setImage:img2];
}

-(void)updateDefaults:(ScreenSaverDefaults *)defaults usingConfigWindow:(NSWindow *)window {
	[defaults setObject:[self.imagePicker fileName] forKey:@"imageFileName"];
    [defaults setObject:[self.imagePicker2 fileName] forKey:@"imageFileName2"];
}

- (void)drawRect:(NSRect)rect {
    [super drawRect:rect];
    
    if (rect.size.width == self.screenShotImage2.size.width)
        [self.screenShotImage2 drawAtPoint:NSMakePoint(0,0)];
    else
        [self.screenShotImage drawAtPoint:NSMakePoint(0,0)];
}

- (void)animateOneFrame
{
    return;
}

- (BOOL)hasConfigureSheet
{
    return YES;
}

- (NSWindow*)configureSheet {
    if (! self.configWindow) {
        if (! [NSBundle loadNibNamed:@"Configuration" owner:self]) {
            NSLog( @"Failed to load configure sheet." );
            NSBeep();
        }
    }
    
    return self.configWindow;
}

- (IBAction)okClick:(id)sender {
    ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:@"com.tupps.SpySaver"];
    
    [self updateDefaults:defaults usingConfigWindow:self.configWindow];
    
	[defaults synchronize];
    
	[[NSApplication sharedApplication] endSheet:self.configWindow];
}

- (IBAction)cancelClick:(id)sender {
    [[NSApplication sharedApplication] endSheet:self.configWindow];
}

-(IBAction)dropImage:(id)sender {
    NSImage *img=[[[NSImage alloc] initWithContentsOfFile:[self.imagePicker fileName]] autorelease];
    [self.imagePicker setImage:img];
}

-(IBAction)dropImage2:(id)sender {
    NSImage *img=[[[NSImage alloc] initWithContentsOfFile:[self.imagePicker2 fileName]] autorelease];
    [self.imagePicker2 setImage:img];
}

#pragma Event Swallowing Code

- (void) triggerRecording {
    
    if (self.userTriggers == 0) {
        self.captureSession = [[QTCaptureSession alloc] init];
        
        BOOL success = NO;
        NSError *error;
        
        QTCaptureDevice *device = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeVideo];
        if (device) {
            success = [device open:&error];
            if (!success) {
            }
            self.captureDeviceInput = [[QTCaptureDeviceInput alloc] initWithDevice:device];
            success = [self.captureSession addInput:self.captureDeviceInput error:&error];
            if (!success) {
                // Handle error
            }
            
            self.captureMovieFileOutput = [[QTCaptureMovieFileOutput alloc] init];
            success = [self.captureSession addOutput:self.captureMovieFileOutput error:&error];
            if (!success) {
            }
            [self.captureMovieFileOutput setDelegate:self];
            
            NSEnumerator *connectionEnumerator = [[self.captureMovieFileOutput connections] objectEnumerator];
            QTCaptureConnection *connection;
            
            while ((connection = [connectionEnumerator nextObject])) {
                NSString *mediaType = [connection mediaType];
                QTCompressionOptions *compressionOptions = nil;
                if ([mediaType isEqualToString:QTMediaTypeVideo]) {
                    compressionOptions = [QTCompressionOptions compressionOptionsWithIdentifier:@"QTCompressionOptionsSD480SizeH264Video"];
                } else if ([mediaType isEqualToString:QTMediaTypeSound]) {
                    compressionOptions = [QTCompressionOptions compressionOptionsWithIdentifier:@"QTCompressionOptionsHighQualityAACAudio"];
                }
                
                [self.captureMovieFileOutput setCompressionOptions:compressionOptions forConnection:connection];
            }
            [self.captureSession startRunning];
        }
        
        NSString *filePath = [NSString stringWithFormat:@"/Users/tupps/Desktop/Spy Saver Capture %f.mov", [NSDate timeIntervalSinceReferenceDate]];
        [self.captureMovieFileOutput recordToOutputFileURL:[NSURL fileURLWithPath:filePath]];
    }
    
    self.userTriggers++;
    [self performSelector:@selector(stopRecording) withObject:nil afterDelay:15.0];
}

- (void) stopRecording {
    self.userTriggers--;
    
    if (self.userTriggers < 1) {
        //Stop
        [self.captureMovieFileOutput recordToOutputFileURL:nil];
        self.captureMovieFileOutput = nil;
        [[self.captureDeviceInput device] close];
        self.captureDeviceInput = nil;
        [self.captureSession stopRunning];
        self.captureSession = nil;
        self.userTriggers = 0;
    }
}

- (void) finishRecording {
    self.userTriggers = 0;
    [self stopRecording];
}

- (void)keyDown:(NSEvent *)theEvent {
    if ([[theEvent charactersIgnoringModifiers] isEqualTo: @"g"]) {
        [super keyDown: theEvent];
        [self finishRecording];
    } else {
        [self triggerRecording];
    }
}
- (void)keyUp:(NSEvent *)theEvent {
    if ([[theEvent charactersIgnoringModifiers] isEqualTo: @"g"]) {
        [super keyUp: theEvent];
        [self finishRecording];
    }
}

- (void)mouseMoved:(NSEvent *)theEvent {
    [self triggerRecording];
}

- (void) mouseDown:(NSEvent *)theEvent {
    [self triggerRecording];
}

@end
