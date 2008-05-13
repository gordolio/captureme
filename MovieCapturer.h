//  Captures movies frame by frame using StillCapturer and saves them.
//
//  Some movie code adapted or taken from http://developer.apple.com/samplecode/QTKitCreateMovie/index.html
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


#import <QTKit/QTKit.h>
#import <Cocoa/Cocoa.h>
#import <QuickTime/QuickTime.h>

@class StillCapturer;

@interface MovieCapturer : NSObject {
	StillCapturer * stillCapturer;	// captures still frames
	
	QTMovie * mMovie;				// the movie we're building
	DataHandler mDataHandlerRef;
	
	NSTimer * captureTimer;
	int framesPerSecond;
	int framesCaptured;				// number frames captured during recording
	int autoStopAfterFrames;
	int autoStopAfterSeconds;
	
	NSRect captureRect;
	
	BOOL isRecording;
	
	NSDate * startTime;
}

- (id)init;

- (void)startCapturingMovieForRect:(NSRect)rect;
- (void)stopCapturingMovie;
- (BOOL)isRecording;

- (void)setAutoStopTime:(int)seconds;

- (int)framesPerSecond;
- (void)setFramesPerSecond:(int)fps;

- (QTMovie *)movie;
- (void)setMovie:(QTMovie *)movie;

@end
