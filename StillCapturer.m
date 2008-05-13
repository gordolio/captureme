//
//  StillCapturer.m
//  Capture Me
//
//  Created by Ryan on 8/31/06.
//  Copyright 2006 Chimoosoft. All rights reserved.
//
//  Some movie code from http://developer.apple.com/samplecode/QTKitCreateMovie/index.html
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.


#import "StillCapturer.h"
#import "FileUtils.h"

@implementation StillCapturer

- (id)init {
    if ((self = [super init])) {
		hasCaptured = NO;
		defaults = [[NSUserDefaults standardUserDefaults] retain];
    }
    return self;
}

- (void) dealloc {
	[capturedImage release];
	[scaledImage release];
	[defaults release];
	
	[super dealloc];
}


- (void)setCapturedImage:(NSImage*)image {
	[image retain];
	[capturedImage release];
	capturedImage = image;
}

- (NSImage*)capturedImage {
	return capturedImage;
}

- (NSImage*)scaledImage {
	return scaledImage;
}

- (void)clearCapture {
	[capturedImage release];	
	capturedImage = nil;
	
	[scaledImage release];		
	scaledImage = nil;
	
	hasCaptured = NO;
}



// captures rect into imageCapture object
- (void)captureScreenForRect:(NSRect)rect {
	hasCaptured = YES;
	
//	CGDirectDisplayID display = CGMainDisplayID();  // old way we did it..
	NSEnumerator * enumerator = [[NSScreen screens] objectEnumerator];
	id obj = nil;
	NSRect screenRect;
	NSScreen * useThisScreen = [NSScreen mainScreen];
	while (obj = [enumerator nextObject]) {
		screenRect = [obj frame];
		if ((rect.origin.x >= screenRect.origin.x) &&
			(rect.origin.x <= screenRect.origin.x + screenRect.size.width) &&
			(rect.origin.y >= screenRect.origin.y) && 
			(rect.origin.y <= screenRect.origin.y + screenRect.size.height)) {
			useThisScreen = obj;
		}
	}
	
	if (nil == useThisScreen) {
		NSLog(@"unable to find a valid screen");
		return;
	}
	
	NSDictionary * descr = [useThisScreen deviceDescription];
	CGDirectDisplayID display = (CGDirectDisplayID)[[descr valueForKey:@"NSScreenNumber"] unsignedIntValue];
	
	CGRect srcRect;
	// the openGL routine expects the srcRect to be relative to its origin.
	srcRect.origin.x = rect.origin.x - [useThisScreen frame].origin.x;
	srcRect.origin.y = rect.origin.y - [useThisScreen frame].origin.y;
	srcRect.size.height = rect.size.height;
	srcRect.size.width = rect.size.width;
	
	CGImageRef ref = grabViaOpenGL(display, srcRect);
	
	[capturedImage release];
	[scaledImage release];
	capturedImage = [[self imageFromCGImageRef:ref] retain];
	scaledImage = [capturedImage copy];
}

- (BOOL)hasCaptured {
	return hasCaptured;
}

- (float)scaledPercentage {
	if (scaledImage == nil) return 100.0;
	
	NSSize ss = [scaledImage size];
	NSSize cs = [capturedImage size];
	
	return (100.0 * ((ss.width * ss.height) / (cs.width * cs.height)));
}

// this method obtained from
// http://developer.apple.com/documentation/Cocoa/Conceptual/CocoaDrawingGuide/Images/chapter_7_section_6.html
- (NSImage*) imageFromCGImageRef:(CGImageRef)image {
    NSRect imageRect = NSMakeRect(0.0, 0.0, 0.0, 0.0);
    CGContextRef imageContext = nil;
    NSImage* newImage = nil;
	
    // Get the image dimensions.
    imageRect.size.height = CGImageGetHeight(image);
    imageRect.size.width = CGImageGetWidth(image);
	
    // Create a new image to receive the Quartz image data.
    newImage = [[NSImage alloc] initWithSize:imageRect.size]; 
    [newImage lockFocus];
	
    // Get the Quartz context and draw.
    imageContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGContextDrawImage(imageContext, *(CGRect*)&imageRect, image);
    [newImage unlockFocus];
	
    return [newImage autorelease];
}



// only scale down, not up.
- (NSImage*)scaleDownToSize:(NSSize)proposedSize {
	if (nil == capturedImage) return nil;
	
	[scaledImage release];
	scaledImage = [capturedImage copy];
	
	NSSize newSize = proposedSize;
	[scaledImage setScalesWhenResized:YES];
	
	if ((proposedSize.width > [scaledImage size].width) ||
		(proposedSize.height > [scaledImage size].height)) {
		
		newSize = [scaledImage size];
	}
	
	[scaledImage setSize:newSize];
	return scaledImage;	// don't autorelease because it's an instance var we're retaining
}


// saves to file named "CM Capture n" where n is the first unused number starting at 1.
- (void)saveToDesktopAsType:(NSBitmapImageFileType)type {
	if (nil == scaledImage) return;
	
	NSString * path = [NSLocalizedString(@"UsersDesktop", @"~/Desktop/") stringByExpandingTildeInPath];	
	NSString * capturePrefix = NSLocalizedString(@"CapturePrefix", @"CM Capture");
	
	NSString * newPath = [FileUtils incrementalNameForDirectoryPath:path andPrefix:capturePrefix];
	if (nil == newPath) return;
	[self saveToFile:newPath asType:type];
}



//	NSTIFFFileType, NSBMPFileType, NSGIFFileType, NSJPEGFileType, NSPNGFileType, NSJPEG2000FileType
- (void)saveToFile:(NSString*)pathWithoutExtension asType:(NSBitmapImageFileType)type {
	if (nil == scaledImage) return;

	NSData *imageData = [scaledImage TIFFRepresentation];
	NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
	
	NSString * ext;
	
	if (type == NSJPEGFileType) ext = @".jpg";
	if (type == NSTIFFFileType) ext = @".tif";
	if (type == NSPNGFileType) ext = @".png";
	if (type == NSGIFFileType) ext = @".gif";
	if (type == NSJPEG2000FileType) ext = @".jp2";	
		
	// note - it looks like quality only affects jpg,jp2, and maybe png.
	float quality = [defaults floatForKey:@"defaultFileQuality"];
	NSDictionary * props = [NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:quality] 
															forKey:NSImageCompressionFactor];
	imageData = [imageRep representationUsingType:type properties:props];
	[imageData writeToFile:[NSString stringWithFormat:@"%@%@", pathWithoutExtension, ext]
				atomically:YES];
}

- (void)copyScaledImageToPasteboardAsType:(NSBitmapImageFileType)type {
	if (nil == scaledImage) return;
	
	NSPasteboard * pb = [NSPasteboard generalPasteboard];

	NSData *imageData = [scaledImage TIFFRepresentation];
	NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];

	// note - it looks like quality only affects jpg,jp2, and maybe png.
	float quality = [defaults floatForKey:@"defaultFileQuality"];
	NSDictionary * props = [NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:quality] 
													   forKey:NSImageCompressionFactor];
	imageData = [imageRep representationUsingType:type properties:props];
	
	[pb declareTypes:[NSArray arrayWithObjects:NSTIFFPboardType, nil] owner:self];
	[pb setData:imageData forType:NSTIFFPboardType];
}


	

@end
