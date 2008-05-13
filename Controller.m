//
//  Controller.m
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

#import "Controller.h"
#import "StillCapturer.h"
#import "MovieCapturer.h"
#import "CMSDefaults.h"
#import <CMSDonations/CMSDonations.h>
#import "CMSCommon.h"
#import "CMSFileUtils.h"

@interface Controller (Private) 

- (void)stopRecording;
- (void)flipCaptureViewIfNecessary;

@end

@implementation Controller (Private)

- (void)stopRecording {
	if ([movieCapturer isRecording]) [movieCapturer stopCapturingMovie];
	[recordingPanel orderOut:self];
	
	[self flipCaptureViewIfNecessary];
	
	[captureWindow makeKeyAndOrderFront:self];
}


- (void)flipCaptureViewIfNecessary {
	// if we were doing a countdown, flip back to the other view showing the capture
	if ([captureWindow contentView] == countView) {
		[captureWindow setContentView:oldContentView];
		[oldContentView release];
		oldContentView = nil;
	}	
}


@end


@implementation Controller

- (id)init {
	if ((self = [super init])) {
		defaults = [NSUserDefaults standardUserDefaults];		
    }
    return self;	
}

- (void)awakeFromNib {
	if (alreadyAwoke) return;
	alreadyAwoke = YES;
	
#if DEBUG
	NSLog(@"Debug Mode Enabled.");
#endif
	
	[CMSCommon quitIfNotTiger];
		
	captureWindow = [self window];
	
	capturer = [[StillCapturer alloc] init];
	movieCapturer = [[MovieCapturer alloc] init];

	NSNotificationCenter * nCenter = [NSNotificationCenter defaultCenter];
	[nCenter addObserver:self
				selector:@selector(stoppedRecording:)
					name:@"CMSStoppedRecording"
				  object:nil];
	
	[self setupDefaults];
	[self setupNotifications];	
	[self setupWindow];
	[self setupCaptureView];
	
}

- (void)setupCaptureView {
	[captureView setDelegate:self];
	[captureView setShouldAcceptFirstMouse:YES];	// for click-through
	
//	NSSize size = [captureWindow contentRectForFrameRect:[captureWindow frame]].size;
//	if ((size.width >= 270) && (size.height >= 270)) {
//		[capturer setCapturedImage:[NSImage imageNamed:@"cm_logo"]];
//		[captureView setImage:[capturer scaleDownToSize:[captureWindow frame].size]];		
//	}
}

- (void)setupNotifications {
	NSNotificationCenter * nCenter = [NSNotificationCenter defaultCenter];
	[nCenter addObserver:self
				selector:@selector(userDefaultsChanged:)
					name:NSUserDefaultsDidChangeNotification
				  object:nil];

	[nCenter addObserver:self
				selector:@selector(captureWindowFromScript:)
					name:@"CMSCaptureWindowNotification"
				  object:nil];
	
}

- (void)setupDefaults {
	
	[CMSDefaults setDefaultObject:@"CM Capture" forKey:@"CaptureNamePrefix"];
	[CMSDefaults setDefaultObject:@"CM Movie" forKey:@"MovieNamePrefix"];

	[CMSDefaults setDefaultBool:YES forKey:@"AutoSaveCaptures"];

	NSString * saveFolder = [@"~/Desktop/" stringByExpandingTildeInPath];
	if (![defaults objectForKey:@"CaptureSaveFolder"]) {		
		[defaults setObject:saveFolder forKey:@"CaptureSaveFolder"];		
		[defaults setObject:[[NSFileManager defaultManager] displayNameAtPath:saveFolder] forKey:@"CaptureSaveFolderName"];
	}
	if (![defaults objectForKey:@"MovieSaveFolder"]) {		
		[defaults setObject:saveFolder forKey:@"MovieSaveFolder"];		
		[defaults setObject:[[NSFileManager defaultManager] displayNameAtPath:saveFolder] forKey:@"MovieSaveFolderName"];
	}
	
	[CMSDefaults setDefaultBool:YES forKey:@"hasBeenLaunchedBefore"];
	[CMSDefaults setDefaultBool:YES forKey:@"windowFloatsGlobally"];
	[CMSDefaults setDefaultBool:NO forKey:@"alreadyDonated"];
	[CMSDefaults setDefaultBool:NO forKey:@"hideWindowAfterCapture"];
	[CMSDefaults setDefaultBool:YES forKey:@"playCaptureSound"];
	[CMSDefaults setDefaultObject:@"PNG" forKey:@"defaultFileFormat"];
	[CMSDefaults setDefaultFloat:1.0 forKey:@"defaultFileQuality"];
	[CMSDefaults setDefaultFloat:0.8 forKey:@"alphaSliderValue"];
	[CMSDefaults setDefaultInteger:0 forKey:@"launchCount"];
	[CMSDefaults setDefaultInteger:5 forKey:@"framesPerSecond"];
	[CMSDefaults setDefaultInteger:10 forKey:@"autoStopRecordingSeconds"];
	[CMSDefaults setDefaultInteger:0 forKey:@"captureDelaySeconds"];
	
	[self updateBasedOnUserDefaultsChange];
}


- (IBAction)chooseCaptureSaveFolder:(id)sender {
	NSString * path = [CMSFileUtils folderSelectionFromUser];
	if (nil == path) return;
	
	[defaults setObject:path forKey:@"CaptureSaveFolder"];
	[defaults setObject:[[NSFileManager defaultManager] displayNameAtPath:path] forKey:@"CaptureSaveFolderName"];
}

- (IBAction)chooseMovieSaveFolder:(id)sender {
	NSString * path = [CMSFileUtils folderSelectionFromUser];
	if (nil == path) return;
	
	[defaults setObject:path forKey:@"MovieSaveFolder"];
	[defaults setObject:[[NSFileManager defaultManager] displayNameAtPath:path] forKey:@"MovieSaveFolderName"];
}



- (IBAction)openReadme:(id)sender {
	[CMSFileUtils openFileInBundle:@"readme.pdf"];
}


- (int)levelForCaptureWindow {
	BOOL defaultFloat = [defaults boolForKey:@"windowFloatsGlobally"];
	
	if (!isFrontmostApplication) {
		// app is not in the front
		if (defaultFloat) return NSFloatingWindowLevel;  // if user prefs say float, then float.
		else return NSNormalWindowLevel;  // else, don't.
	}
	
	// else, app is in the front, so behave normally
	return NSNormalWindowLevel;
}

- (void)setupWindow {	
	[captureWindow setLevel:[self levelForCaptureWindow]];
	[captureWindow setHidesOnDeactivate:NO];
	[captureWindow setFrameUsingName:@"mainWindow"];
	[captureWindow setMovableByWindowBackground:YES];
	[captureWindow setExcludedFromWindowsMenu:NO];
	
	[captureWindow setAlphaValue:[defaults floatForKey:@"alphaSliderValue"]];
	[self setWindowTitleForSize:[[captureWindow contentView] frame].size];
	[captureWindow makeKeyAndOrderFront:self];
}


- (void)stoppedRecording:(NSNotification *)notification {
	[self stopRecording];
}

- (void)showRecordingWindow {
	[recordingPanel setLevel:[self levelForCaptureWindow]];
	[recordingPanel setHidesOnDeactivate:NO];
	[recordingPanel setMovableByWindowBackground:YES];
	[recordingPanel setExcludedFromWindowsMenu:YES];
	
	/*
	NSRect captureFrame = [captureWindow frame];
	NSRect recordingFrame = [recordingPanel frame];
	
	recordingFrame.origin = captureFrame.origin;
	
	if ((captureFrame.origin.y - (captureFrame.size.height + [recordingPanel frame].size.height + 20)) < 0) {
		// then put panel below capture window
		recordingFrame.origin.y += captureFrame.size.height + 10;
	} else {
		// put panel above capture window
		recordingFrame.origin.y -= captureFrame.size.height + 10;
	}
	
	[recordingPanel setFrameOrigin:recordingFrame.origin];
	*/
	
	[recordingPanel setAlphaValue:0.8];
	[recordingPanel makeKeyAndOrderFront:self];	
}

- (void)setWindowTitleForSize:(NSSize)size {
	NSString * name = @"";
	if (size.width > 250) {
		name = @"Capture Me - ";
	}
	
	NSString * title;
	
	if ([capturer scaledPercentage] < 100.0) {
		title = [NSString stringWithFormat:@"%@%1.0f x %1.0f (%1.0f%%)", name, size.width, size.height, [capturer scaledPercentage]];
	} else {
		title = [NSString stringWithFormat:@"%@%1.0f x %1.0f", name, size.width, size.height];
	}
	
	[captureWindow setTitle:title];
}

// action methods

- (IBAction)setAlphaFromSlider:(id)sender {
	[captureWindow setAlphaValue:[sender floatValue]];	
}

- (IBAction)runSaveDialog:(id)sender {
	NSSavePanel * savePanel = [NSSavePanel savePanel];
	[savePanel setAccessoryView:saveAccessoryView];
	
	[savePanel beginSheetForDirectory:nil
								 file:nil 
					   modalForWindow:captureWindow 
						modalDelegate:self
					   didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:)
						  contextInfo:nil];
}

- (void)savePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo {
	if (returnCode == NSFileHandlingPanelOKButton) {
		[capturer saveToFile:[sheet filename] asType: [self typeForDefault]];
	}
}

- (void)setQualitySliderEnabled {
	// do nothing..
}

- (BOOL)qualitySliderEnabled {
	NSBitmapImageFileType type = [self typeForDefault];
	if ((type == NSJPEGFileType) || (type == NSJPEG2000FileType)) {
		return YES;
	} else {
		return NO;	
	}
	
}

- (IBAction)showAboutPanel:(id)sender {
	if (nil == aboutPanel) {
		if (![NSBundle loadNibNamed:@"About.nib" owner:self] ) {
			NSLog(@"Load of About.nib failed");
			return;
		}
	}

	[aboutPanel setOneShot:YES];
	[aboutPanel makeKeyAndOrderFront:nil];	
}

- (IBAction)showPreferencesWindow:(id)sender {
	if (nil == preferencesWindow) {
		if (![NSBundle loadNibNamed:@"Preferences.nib" owner:self] ) {
			NSLog(@"Load of Preferences.nib failed");
			return;
		}
	}

	[preferencesWindow setOneShot:YES];
	[preferencesWindow makeKeyAndOrderFront:nil];
}




- (BOOL)validateMenuItem:(NSMenuItem *)item {
	SEL action = [item action];
	
	BOOL sheetsOut = ([alphaWindow isVisible] || [sizeWindow isVisible]);
	
    if ((action == @selector(runSaveDialog:)) || 
		(action == @selector(saveToDesktop:)) || 
		(action == @selector(clearCapture:))) {
		return ([capturer hasCaptured] && !sheetsOut);
    }
	if (action == @selector(toggleCaptureWindowVisibility:)) {
		if ([captureWindow isVisible] && (![captureWindow isMiniaturized])) {
			[item setTitle:NSLocalizedString(@"Hide Capture Window", @"")];
		} else {
			[item setTitle:NSLocalizedString(@"Show Capture Window", @"")];			
		}
		return YES;
    }
	if ((action == @selector(captureMainWindow:)) ||
		(action == @selector(captureEntireScreen:))) {
		return ((![drawTimer isValid]) && !sheetsOut);
	}
	if ((action == @selector(showAlphaSheet:)) ||
		(action == @selector(showSizeSheet:))) {
		return  !sheetsOut;
	}
	
	if ([item tag] == 3000) {		
		if ([movieCapturer isRecording]) [item setTitle:NSLocalizedString(@"Stop Recording", @"")];
		else [item setTitle:NSLocalizedString(@"Start Recording", @"")];
	}
		
    return YES;
}

- (IBAction)toggleCaptureWindowVisibility:(id)sender {
	if ([captureWindow isVisible] && (![captureWindow isMiniaturized])) {
		[captureWindow orderOut:sender];
	} else {
		[captureWindow makeKeyAndOrderFront:sender];
		[captureWindow deminiaturize:sender];
	}
}



- (void)hideWindowThenRecord {
	[captureWindow orderOut:self];
	[self showRecordingWindow];
	
	[movieCapturer setFramesPerSecond:[defaults integerForKey:@"framesPerSecond"]];
	[movieCapturer setAutoStopTime:[defaults integerForKey:@"autoStopRecordingSeconds"]];
	[movieCapturer startCapturingMovieForRect:[captureWindow contentRectForFrameRect:[captureWindow frame]]];
}

- (IBAction)record:(id)sender {
	if ([movieCapturer isRecording]) {
		[self stopRecording];
	} else {
		[self startCountdownTimerFor:MOVIE];
	}	
}


- (IBAction)closeThisWindow:(id)sender {
	[[sender window] close];
}

- (IBAction)showAlphaSheet:(id)sender {
	[slider setTarget:self];
	[alphaWindow setOneShot:YES];
	[[NSApplication sharedApplication] beginSheet:alphaWindow
								   modalForWindow:captureWindow
									modalDelegate:self
								   didEndSelector:nil
									  contextInfo:nil];
	shiftKeyDown = NO;
}

- (IBAction)showSizeSheet:(id)sender {
	[self willChangeValueForKey:@"captureWidth"];
	[self didChangeValueForKey:@"captureWidth"];
	[self willChangeValueForKey:@"captureHeight"];
	[self didChangeValueForKey:@"captureHeight"];

	[sizeWindow setOneShot:YES];
	[[NSApplication sharedApplication] beginSheet:sizeWindow
								   modalForWindow:captureWindow
									modalDelegate:self
								   didEndSelector:nil
									  contextInfo:nil];
	shiftKeyDown = NO;
}

- (void)fadeCaptureWindow {
	NSViewAnimation * anim;
	NSMutableDictionary * viewDict;

	viewDict = [NSMutableDictionary dictionaryWithCapacity:2];	
	[viewDict setObject:captureWindow forKey:NSViewAnimationTargetKey];

	// fade out
	[viewDict setObject:NSViewAnimationFadeOutEffect forKey:NSViewAnimationEffectKey];

	anim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray
				arrayWithObjects:viewDict, nil]];

	[anim setDuration:1.2];
	[anim setAnimationCurve:NSAnimationEaseIn];

	[anim startAnimation];
	[anim release];
}

- (void)sliderIsDoneMoving {
	[[NSApplication sharedApplication] endSheet:alphaWindow];
	[alphaWindow orderOut:self];
}

- (IBAction)doneSizing:(id)sender {
	[[NSApplication sharedApplication] endSheet:sizeWindow];
	[sizeWindow orderOut:self];	
}


- (void)imageViewClicked:(NSImageView *)sender {
	[self captureMainWindow:sender];
}



- (IBAction)captureMainWindow:(id)sender {	
	shouldCaptureScreen = NO;	
	[self startCountdownTimerFor:STILL];
}

- (IBAction)captureEntireScreen:(id)sender {
	shouldCaptureScreen = YES;	
	[self startCountdownTimerFor:STILL];
}


- (void)startCountdownTimerFor:(CaptureType)type {
	int delay = [defaults integerForKey:@"captureDelaySeconds"];

	countType = type;
	
	if (delay < 1) {
		switch (type) {
		case MOVIE:
			[self hideWindowThenRecord];
			break;
		case STILL:
			[self hideWindowThenCapture];
			break;
		}
		
		return;
	}
	
	[oldContentView release];
	oldContentView = [[captureWindow contentView] retain];
	[captureWindow setContentView:countView];
	
	drawTimerTimeLeft = delay;
	
	[self destroyDrawTimer];
	[self updateCaptureCountdown];
	
	if (!drawTimer) {  //then create it
		drawTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0
													  target:self
													selector:@selector(updateCaptureCountdown)
													userInfo:0 repeats:YES] retain];
	}		
}

- (void)updateCaptureCountdown {
	if (drawTimerTimeLeft < 1) {
		[self destroyDrawTimer];
	
		switch (countType) {
			case MOVIE:
				[self hideWindowThenRecord];				
				break;
			case STILL:
				[self hideWindowThenCapture];
				break;
		}
		
		return;
	}
	
	[countField setStringValue:[NSString stringWithFormat:@"%d", drawTimerTimeLeft]];
	
	drawTimerTimeLeft--;	
}

- (void)hideWindowThenCapture {
	if ([defaults boolForKey:@"playCaptureSound"]) {
		if (nil == shutterSound) shutterSound = [[NSSound soundNamed:@"Shutter.aiff"] retain];
		[shutterSound play];
	}
	
	[captureWindow orderOut:self];
	
	if (shouldCaptureScreen) {
		[self performSelector:@selector(doCaptureMainScreen) withObject:nil afterDelay:0.2];
	} else {
		[self performSelector:@selector(doCaptureMainWindow) withObject:nil afterDelay:0.2];
	}
}

- (void)doCaptureMainWindow {
	[self captureRect:[captureWindow contentRectForFrameRect:[captureWindow frame]]
			 andScale:NO toRatio:1.0];
}

- (void)doCaptureMainScreen {
	[self captureRect:[[NSScreen mainScreen] frame]
			 andScale:YES
			  toRatio:0.5];
	optionKeyDown = NO;  // for some reason, it sticks after command-option-k.
}


- (void)captureRect:(NSRect)rect andScale:(BOOL)shouldScale toRatio:(float)ratio {
	NSSize newSize;
	NSRect newFrame;
	
	int deltaX = [captureWindow frame].size.width - newFrame.size.width;
	int deltaY = [captureWindow frame].size.height - newFrame.size.height;

	if (shouldScale) {	
		newSize.width = rect.size.width * ratio;
		newSize.height = rect.size.height * ratio;
		
		newFrame.origin = [captureWindow frame].origin;
		newFrame.size.width = newSize.width;
		newFrame.size.height = newSize.height;
	}
	
	[capturer captureScreenForRect:rect];

	if (shouldScale) [capturer scaleDownToSize:newSize];
	
	[self flipCaptureViewIfNecessary];
	
	if (shouldScale) {
		NSRect windowFrame = newFrame;
		windowFrame.size.width += deltaX;
		windowFrame.size.height += deltaY;
		[captureWindow setFrame:newFrame display:YES];
	}
	[self setWindowTitleForSize:[[captureWindow contentView] frame].size];
	
	[captureView setImage:[capturer scaledImage]];
	[helpTextField setHidden:YES];
	
	[captureWindow makeKeyAndOrderFront:self];
	
	if ((!isFrontmostApplication) && [defaults boolForKey:@"hideWindowAfterCapture"]) {
		[self fadeCaptureWindow];
	}
	
	if ([defaults boolForKey:@"saveCapturesToDesktop"])  {
		[self saveToDesktop:self];
	}
	if ([defaults boolForKey:@"copyCapturesToClipboard"])  {
		[capturer copyScaledImageToPasteboardAsType:[self typeForDefault]];
	}		
}

// remember to use [[NSFileManager defaultManager] displayNameAtPath:path] to get localized names

- (IBAction)saveToDesktop:(id)sender {
	[capturer saveToDesktopAsType:[self typeForDefault]];
}

- (IBAction)openChimoosoftHome:(id)sender {
	[CMSCommon openChimoosoftHomePage];
}

- (IBAction)openURLForTitle:(id)sender {
	if (sender == mailToButton) {
		[self sendFeedback:self];
	} else {
		[CMSCommon openURLFromString:[sender alternateTitle]];
	}
}

- (IBAction)copy:(id)sender {
	[capturer copyScaledImageToPasteboardAsType:[self typeForDefault]];
}

- (IBAction)cut:(id)sender {
	[capturer copyScaledImageToPasteboardAsType:[self typeForDefault]];
	[self clearCapture:sender];
}


- (IBAction)sendFeedback:(id)sender {
	[CMSCommon composeEmailTo:@"support@chimoosoft.com"
				  withSubject:[NSString stringWithFormat:@"Capture Me %@ Support", [CMSCommon applicationVersionString]]
					  andBody:[NSString stringWithFormat:@"Capture Me Version %@", [CMSCommon applicationVersionString]]];	
}



- (IBAction)clearCapture:(id)sender {
	[capturer clearCapture];
	[captureView setImage:[capturer capturedImage]];
	[helpTextField setHidden:NO];
	[self setWindowTitleForSize:[[captureWindow contentView] frame].size];
}

- (NSBitmapImageFileType)typeForDefault {
	NSString * type = [defaults stringForKey:@"defaultFileFormat"];
	
	if ([type isEqualToString:@"PNG"]) return NSPNGFileType;
	if ([type isEqualToString:@"JPEG"]) return NSJPEGFileType;
	if ([type isEqualToString:@"JPEG 2000"]) return NSJPEG2000FileType;
	if ([type isEqualToString:@"TIFF"]) return NSTIFFFileType;
	if ([type isEqualToString:@"GIF"]) return NSGIFFileType;
	
	return NSPNGFileType;
}



// only scale down, not up.
- (void)scaleIfPictureExists:(NSSize)proposedFrameSize {
	if (nil == [capturer capturedImage]) return;
	[captureView setImage:[capturer scaleDownToSize:proposedFrameSize]];
}


- (void)setCaptureWidth:(int)newWidth {
	NSRect newFrame = [captureWindow frame];
	newFrame.size.width = newWidth;
	
	[captureWindow setFrame:newFrame
					display:YES 
					animate:YES];	
}

- (int)captureWidth {
	return [captureWindow frame].size.width;
}

- (void)setCaptureHeight:(int)newHeight {
	int diff = [captureWindow frame].size.height - [[captureWindow contentView] frame].size.height;
	
	NSRect newFrame = [captureWindow frame];
	newFrame.size.height = newHeight + diff;
	
	[captureWindow  setFrame:newFrame
					display:YES 
					animate:YES];
}

- (int)captureHeight {
	return [[captureWindow contentView] frame].size.height;	
}


///////////////////
// delegate methods
///////////////////


- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)proprosedFrameSize {	
	if (sender != captureWindow) return proprosedFrameSize;
	
	NSSize newSize = proprosedFrameSize;
	int minW = [captureWindow minSize].width;
	//int minH = [captureWindow minSize].height;
	
	float r;
	// force proportional scaling if shift key is down
	if (shiftKeyDown) {
		r = ((float)([sender frame].size.width)) / ((float)([sender frame].size.height));
		newSize.width = newSize.height * r;
		if (newSize.width < minW) {
			newSize.width = minW;
			newSize.height = newSize.width * (1/r);
		}
	}
	
	return newSize;
}



- (void)windowDidResize:(NSNotification *)aNotification {
	if ([aNotification object] != captureWindow) return;
	
	NSSize s = [[captureWindow contentView] frame].size;
	
	[self setWindowTitleForSize:s];
	[self scaleIfPictureExists:s];
}

- (void)windowWillClose:(NSNotification *)aNotification {
	if ([aNotification object] == aboutPanel) {
		aboutPanel = nil;
	}
	if ([aNotification object] == preferencesWindow) {
		preferencesWindow = nil;
	}
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification {
}


 - (void)keyDown:(NSEvent *)theEvent {
	int deltaX = 0;
	int deltaY = 0;
	
	int offset = 1;
	if (([theEvent modifierFlags] & NSAlternateKeyMask) == NSAlternateKeyMask) {
		offset = 10;
	}
	
	if ([theEvent modifierFlags] & NSNumericPadKeyMask) { // arrow keys have this mask
        NSString *theArrow = [theEvent charactersIgnoringModifiers];
        unichar keyChar = 0;
        if ( [theArrow length] == 0 )
            return;            // reject dead keys
        if ( [theArrow length] == 1 ) {
            keyChar = [theArrow characterAtIndex:0];
            if ( keyChar == NSLeftArrowFunctionKey ) deltaX = -offset;
			if ( keyChar == NSRightArrowFunctionKey ) deltaX = offset;
			if ( keyChar == NSUpArrowFunctionKey ) deltaY = offset;
			if ( keyChar == NSDownArrowFunctionKey ) deltaY = -offset;			
		}
	}
				
	NSPoint newOrigin = [captureWindow frame].origin;
	newOrigin.x += deltaX;
	newOrigin.y += deltaY;

	[captureWindow setFrameOrigin:newOrigin];
	
}


- (void)flagsChanged:(NSEvent *)theEvent {
	shiftKeyDown = NO;
	optionKeyDown = NO;
	
	if (([theEvent modifierFlags] & NSShiftKeyMask) == NSShiftKeyMask) {
		shiftKeyDown = YES;
	}
	
	if (([theEvent modifierFlags] & NSAlternateKeyMask) == NSAlternateKeyMask) {
		optionKeyDown = YES;
	}
}

- (IBAction)donate:(id)sender {
	[CMSCommon openDonationPage];
}


//////////////////
// notifications
//////////////////

- (void)applicationDidFinishLaunching:(NSNotification*)notification {		

	[CMSDonations setupWithDollarCost:@"$15"];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	[captureWindow saveFrameUsingName:@"mainWindow"];
}

- (void)applicationDidResignActive:(NSNotification *)aNotification {
	isFrontmostApplication = NO;
	[captureWindow setLevel:[self levelForCaptureWindow]];
	
}

- (void)applicationWillBecomeActive:(NSNotification *)aNotification {
	if ([movieCapturer isRecording]) return;
	
	[captureWindow setAlphaValue:[defaults floatForKey:@"alphaSliderValue"]];
	[captureWindow makeKeyAndOrderFront:self];
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification {
	isFrontmostApplication = YES;
	[captureWindow setLevel:[self levelForCaptureWindow]];
}

- (void)userDefaultsChanged:(NSNotification *)aNotification {
	[self updateBasedOnUserDefaultsChange];
}

- (void)updateBasedOnUserDefaultsChange {
	[captureWindow setLevel:[self levelForCaptureWindow]];
	
	// need to do this for cocoa bindings to update properly
	[self willChangeValueForKey:@"qualitySliderEnabled"];
	[self didChangeValueForKey:@"qualitySliderEnabled"];
}

- (void)scrollWheel:(NSEvent *)theEvent {
	if ([theEvent window] != captureWindow) return;
		
	NSRect oldRect = [captureWindow frame];
	NSRect newRect;
	int minWidth = [captureWindow minSize].width;
	int minHeight = [captureWindow minSize].height;

	float deltaX = [theEvent deltaX];
	float deltaY = [theEvent deltaY];

	if (optionKeyDown) {
		// option key means move instead of resize
		newRect.origin.x = oldRect.origin.x - deltaX;
		newRect.origin.y = oldRect.origin.y + deltaY;
		newRect.size = oldRect.size;
	} else {	
		// no option key down, so resize
		newRect.origin.x = oldRect.origin.x;
		newRect.origin.y = oldRect.origin.y - deltaY;
		newRect.size.width = oldRect.size.width + deltaY;
		newRect.size.height = oldRect.size.height + deltaY;
		
		if (newRect.size.width < minWidth) newRect.size.width = minWidth;
		if (newRect.size.height < minHeight) newRect.size.height = minHeight;
	}
	
	[captureWindow setFrame:newRect display:YES animate:YES];
}

// applescript
- (void)captureWindowFromScript:(NSNotification *)aNotification {
	[self captureMainWindow:self];
}

- (void)destroyDrawTimer {
	if (nil == drawTimer) return;
	
	if ([drawTimer isValid]) [drawTimer invalidate]; //stop it

	[drawTimer release];
	drawTimer = nil;  //note, do I have a memory leak here?  I'm not sure.
}


- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[capturer release];
	[movieCapturer release];
	[shutterSound release];
	
	[self destroyDrawTimer];
	[super dealloc];
}

// Delegate methods for CMSVersioning.

- (NSURL*)productURL {
	return [NSURL URLWithString:@"http://www.chimoosoft.com/products/captureme/"];
}


@end
