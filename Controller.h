//
//  Controller.h
//  Capture Me
//
//  Created by Ryan on 8/27/06.
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
#import "CMSSliderCell.h"
#import "CMSClickableImageView.h"

typedef enum {
	STILL		= 1001,
	MOVIE		= 1002
} CaptureType;


@class MovieCapturer;
@class StillCapturer;

@interface Controller : NSWindowController {
	CaptureType countType;
	
	StillCapturer * capturer;	
	MovieCapturer * movieCapturer;
	
	NSWindow * captureWindow;
	NSView * oldContentView;

	NSTimer * drawTimer;
	
	int drawTimerTimeLeft;
	
	NSSound * shutterSound;

	IBOutlet CMSClickableImageView * captureView;
	IBOutlet id aboutPanel;
	IBOutlet id countView;
	IBOutlet id countField;
	
	IBOutlet id helpTextField;
	IBOutlet id preferencesWindow;
	IBOutlet id alphaWindow;
	IBOutlet id sizeWindow;
	IBOutlet id slider;
	IBOutlet id mailToButton;	
	IBOutlet id recordingPanel;
	
	IBOutlet id saveAccessoryView;
	
	NSUserDefaults * defaults;
	BOOL isFirstLaunch;
	BOOL shiftKeyDown, optionKeyDown;
	BOOL alreadyAwoke;
	BOOL shouldCaptureScreen;
	
	BOOL isFrontmostApplication;
	
}


- (IBAction)toggleCaptureWindowVisibility:(id)sender;
- (IBAction)clearCapture:(id)sender;
- (IBAction)showAboutPanel:(id)sender;
- (IBAction)showPreferencesWindow:(id)sender;
- (IBAction)captureMainWindow:(id)sender;
- (IBAction)captureEntireScreen:(id)sender;
- (IBAction)showAlphaSheet:(id)sender;
- (IBAction)showSizeSheet:(id)sender;
- (IBAction)doneSizing:(id)sender;
- (IBAction)donate:(id)sender;

- (IBAction)record:(id)sender;

- (IBAction)openURLForTitle:(id)sender;
- (IBAction)setAlphaFromSlider:(id)sender;
- (IBAction)sendFeedback:(id)sender;
- (IBAction)copy:(id)sender;
- (IBAction)cut:(id)sender;
- (IBAction)saveToDesktop:(id)sender;
- (IBAction)runSaveDialog:(id)sender;
- (IBAction)closeThisWindow:(id)sender;
- (IBAction)openReadme:(id)sender;
- (IBAction)openChimoosoftHome:(id)sender;

- (IBAction)chooseCaptureSaveFolder:(id)sender;
- (IBAction)chooseMovieSaveFolder:(id)sender;

- (void)setQualitySliderEnabled;
- (BOOL)qualitySliderEnabled;

- (void)setCaptureWidth:(int)newWidth;
- (int)captureWidth;
- (void)setCaptureHeight:(int)newHeight;
- (int)captureHeight;

- (void)awakeFromNib;
- (void)setupNotifications;
- (void)setupDefaults;
- (void)setupWindow;
- (void)setupCaptureView;
- (void)setWindowTitleForSize:(NSSize)size;
- (void)sliderIsDoneMoving;

- (void)imageViewClicked:(NSImageView*)sender;
- (void)updateBasedOnUserDefaultsChange;

- (void)scaleIfPictureExists:(NSSize)proposedFrameSize;
- (NSBitmapImageFileType)typeForDefault;
- (void)startCountdownTimerFor:(CaptureType)type;
- (void)hideWindowThenCapture;
- (void)updateCaptureCountdown;
- (void)captureRect:(NSRect)rect andScale:(BOOL)shouldScale toRatio:(float)ratio;

// applescript
- (void)captureWindowFromScript:(NSNotification *)aNotification;

- (void)dealloc;
- (void)destroyDrawTimer;

// Delegate methods for CMSVersioning.
- (NSURL*)productURL;

@end
