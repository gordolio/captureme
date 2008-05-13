//
//  StillCapturer.h
//  Capture Me
//
//  Created by Ryan on 8/31/06.
//  Copyright 2006 Chimoosoft. All rights reserved.
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


#import <Cocoa/Cocoa.h>
#import "glGrab.h"

@interface StillCapturer : NSObject {
	NSUserDefaults * defaults;
	
	NSImage * capturedImage;
	NSImage * scaledImage;
	
	BOOL hasCaptured;
}

- (void)setCapturedImage:(NSImage*)image;
- (void)captureScreenForRect:(NSRect)rect;
- (NSImage*)capturedImage;
- (NSImage*)scaledImage;
- (NSImage*)scaleDownToSize:(NSSize)proposedSize;
- (NSImage*)imageFromCGImageRef:(CGImageRef)image;

- (void)clearCapture;
- (BOOL)hasCaptured;
- (void)saveToDesktopAsType:(NSBitmapImageFileType)type;
- (void)saveToFile:(NSString*)pathWithoutExtension asType:(NSBitmapImageFileType)type;

- (float)scaledPercentage;
- (void)copyScaledImageToPasteboardAsType:(NSBitmapImageFileType)type;

@end
