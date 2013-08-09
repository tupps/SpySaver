//
//  SpySaverView.h
//  SpySaver
//
//  Created by Luke Tupper on 6/08/13.
//  Copyright (c) 2013 Luke Tupper. All rights reserved.
//

#import <ScreenSaver/ScreenSaver.h>

@class LTImagePicker;

@interface SpySaverView : ScreenSaverView

@property (nonatomic, strong) IBOutlet NSWindow *configWindow;

@property (nonatomic, strong) IBOutlet LTImagePicker *imagePicker;
@property (nonatomic, strong) IBOutlet LTImagePicker *imagePicker2;

- (IBAction)okClick:(id)sender;
- (IBAction)cancelClick:(id)sender;
- (IBAction)dropImage:(id)sender;
- (IBAction)dropImage2:(id)sender;

@end
