/********************************************************************************
 Copyright (c) 2011-2014, jemast software
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * Neither the name of the <organization> nor the
 names of its contributors may be used to endorse or promote products
 derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 ********************************************************************************/


#import "SplashScreenImageView.h"

@implementation SplashScreenImageView

# pragma mark Drag & Drop

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    if (!self.isEnabled)
        return NSDragOperationNone;
    
	NSPasteboard *pb = [sender draggingPasteboard];
	NSString *type = [pb availableTypeFromArray:[NSArray arrayWithObjects: NSFilenamesPboardType,(NSString *)kUTTypeAppleICNS, nil]];
	if (type) {
        NSArray *fileNameData = [pb propertyListForType:NSFilenamesPboardType];
        NSString *firstFileName = [fileNameData objectAtIndex:0];
        if ([firstFileName isLike:@"*.tif"]) {
            return NSDragOperationCopy;
        }
	}
    
	return NSDragOperationNone;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
    if (!self.isEnabled)
        return NSDragOperationNone;
    
	NSPasteboard *pb = [sender draggingPasteboard];
	NSString *type = [pb availableTypeFromArray:[NSArray arrayWithObjects: NSFilenamesPboardType,(NSString *)kUTTypeAppleICNS, nil]];
	if (type) {
        NSArray *fileNameData = [pb propertyListForType:NSFilenamesPboardType];
        NSString *firstFileName = [fileNameData objectAtIndex:0];
        if ([firstFileName isLike:@"*.tif"]) {
            return NSDragOperationCopy;
        }
	}
    
    return NSDragOperationNone;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
    if (!self.isEnabled)
        return NO;
    
	return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    if (!self.isEnabled)
        return NO;
    
    NSPasteboard *pb = [sender draggingPasteboard];
    
	// Try getting filename data first
	NSArray *fileNameData = [pb propertyListForType:NSFilenamesPboardType];
	NSString *firstFileName = [fileNameData objectAtIndex:0];
	if ([firstFileName isLike:@"*.tif"]) {
		[self setImage:[[NSImage alloc] initWithContentsOfFile:firstFileName]];
        [self.image setName:firstFileName];
        [self sendAction:[self action] to:[self target]];
	}
    
	return YES;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender {
}

@end
