#import <Cocoa/Cocoa.h>

@interface LTImagePicker:NSImageView {
	NSString *filename;
}

-(void)concludeDragOperation:(id <NSDraggingInfo>)sender;
-(void)setFileName:(NSString *)newname;
-(NSString *)fileName;

@end
