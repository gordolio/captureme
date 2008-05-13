//  Most movie code adapted or taken from http://developer.apple.com/samplecode/QTKitCreateMovie/index.html
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

#import "MovieCapturer.h"
#import "FileUtils.h"
#import "QTMovieExtensions.h"
#import "StillCapturer.h"

@interface MovieCapturer (Private)

- (void)destroyTimer;
- (void)addImageToMovie:(NSImage *)image;
- (void)saveToDesktop;
- (BOOL)writeToPath:(NSString *)path ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation error:(NSError **)outError;
- (void)buildQTKitMovie;
-(Movie)quicktimeMovieFromTempFile:(DataHandler *)outDataHandler error:(OSErr *)outErr;

@end


@implementation MovieCapturer (Private)

- (void)destroyTimer {
	[captureTimer invalidate];
	[captureTimer release];
	captureTimer = nil;	
}

- (void)addImageToMovie:(NSImage *)image {
	if (nil == mMovie) [self buildQTKitMovie];
	if ((nil == mMovie) || (nil == image)) return;
	
	if (nil == startTime) startTime = [[NSDate date] retain];
	
	[mMovie CMSAddImage:image];
	framesCaptured++;
	
	if (fabs([startTime timeIntervalSinceNow]) >= autoStopAfterSeconds) {
		[self stopCapturingMovie];
	}
}

- (void)saveToDesktop {
	if (nil == mMovie) return;
	
	NSString * path = [NSLocalizedString(@"UsersDesktop", @"~/Desktop/") stringByExpandingTildeInPath];	
	NSString * capturePrefix = @"CM Movie";
	
	NSString * newPath = [NSString stringWithFormat:@"%@.mov", [FileUtils incrementalNameForDirectoryPath:path andPrefix:capturePrefix]];
	if (nil == newPath) return;
	
	
	[self writeToPath:newPath
			   ofType: nil
	 forSaveOperation: NSSaveOperation
				error:nil];	
	
}

// Write to a movie file
// Most of this method is from Apple.
- (BOOL)writeToPath:(NSString *)path ofType:(NSString *)typeName 
   forSaveOperation:(NSSaveOperationType)saveOperation error:(NSError **)outError {
	
    BOOL success = NO;
	
	switch (saveOperation) {	
		case NSSaveOperation: 
		{
			success = [mMovie flattenToFilePath:path];
			
			// movie file does not exist, so we'll flatten our in-memory movie to the file
			
			// release our old in-memory movie
			[mMovie release];
			mMovie = nil;
			
			// re-acquire movie from the new movie file
			mMovie = [QTMovie movieWithFile:path error:nil];
			[mMovie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieEditableAttribute];
			[mMovie retain];
		}
			
			break;
			
		case NSSaveAsOperation:
		case NSSaveToOperation:
			// flatten movie (make it self-contained)
			success = [mMovie flattenToFilePath: path];
			
			break;
			
	}
	
    return success;
}


// Build a QTKit movie from a series of image frames
// Most of this method is from Apple.
- (void)buildQTKitMovie {
	
	/*  
	 NOTES ABOUT CREATING A NEW ("EMPTY") MOVIE AND ADDING IMAGE FRAMES TO IT
	 
	 In order to compose a new movie from a series of image frames with QTKit
	 it is of course necessary to first create an "empty" movie to which these
	 frames can be added. Actually, the real requirements (in QuickTime terminology)
	 for such an "empty" movie are that it contain a writable data reference. A
	 movie with a writable data reference can then accept the addition of image 
	 frames via the -addImage method.
	 
	 A future version of QTKit will provide a simple Obj C method for creating 
	 a QTMovie with a writable data reference.
	 
	 In the meantime, we can use the native QuickTime API CreateMovieStorage to create
	 a QuickTime movie with a writable data reference (in our example below we use a
	 data reference to a file). We then use the QTKit movieWithQuickTimeMovie: method to
	 instantiate a QTMovie from this QuickTime movie. 
	 
	 Finally, images are added to the movie as movie frames using -addImage.
	 */
	
	OSErr err;
	// create a QuickTime movie
	Movie qtMovie = [self quicktimeMovieFromTempFile:&mDataHandlerRef error:&err];
	if (nil == qtMovie) return;
	
	// instantiate a QTMovie from our QuickTime movie
	mMovie = [QTMovie movieWithQuickTimeMovie:qtMovie disposeWhenDone:YES error:nil];
	if (!mMovie || err) return;
	
	// mark the movie as editable
	[mMovie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieEditableAttribute];
	
	// keep it around until we are done with it...
	[mMovie retain];
	
	//new
	GWorldPtr gworld = NULL;
	Rect bounds = { 0, 0, 100, 100 };
	err = QTNewGWorld( &gworld, 0, &bounds, NULL, NULL, 0 );
	if( err ) NSLog(@"QTNewGWorld probelm");
	
	SetMovieGWorld( qtMovie, gworld, NULL );
}


// Creates a QuickTime movie file from a temporary file
// Most of this method is from Apple.
-(Movie)quicktimeMovieFromTempFile:(DataHandler *)outDataHandler error:(OSErr *)outErr {
	*outErr = -1;
	
	// generate a name for our movie file
	NSString *tempName = [NSString stringWithCString:tmpnam(nil) 
											encoding:[NSString defaultCStringEncoding]];
	if (nil == tempName) return nil;
	
	Handle dataRefH = nil;
	OSType dataRefType;
	
	// create a file data reference for our movie
	*outErr = QTNewDataReferenceFromFullPathCFString((CFStringRef)tempName,
													 kQTNativeDefaultPathStyle,
													 0,
													 &dataRefH,
													 &dataRefType);
	if (*outErr != noErr) return nil;
	
	// create a QuickTime movie from our file data reference
	Movie	qtMovie	= nil;
	CreateMovieStorage (dataRefH,
						dataRefType,
						'TVOD',
						smSystemScript,
						newMovieActive, 
						outDataHandler,
						&qtMovie);
	*outErr = GetMoviesError();
	if (*outErr != noErr) {
		DisposeHandle(dataRefH);
		return nil;
	}
	
	return qtMovie;
}





@end



@implementation MovieCapturer

- (id)init {
    self = [super init];

    if (self) {
		mMovie = nil;
		mDataHandlerRef = nil;
		stillCapturer = nil;
		framesPerSecond = 1;
		autoStopAfterFrames = 60;
		autoStopAfterSeconds = 10;
		captureTimer = nil;
		startTime = nil;		
		isRecording = NO;
    }
	
    return self;
}


- (void)dealloc {
	[mMovie release];
	[stillCapturer release];
	[self destroyTimer];

	[startTime release];
	
	if (mDataHandlerRef) CloseMovieStorage(mDataHandlerRef);
	
	[super dealloc];
}

- (NSTimeInterval)timerInterval {
	return 1.0 / (float)framesPerSecond;
}

- (void)createTimer {
	[self destroyTimer];
	
	captureTimer = [[NSTimer scheduledTimerWithTimeInterval:[self timerInterval]
													 target:self
												   selector:@selector(timerUpdate:)
												   userInfo:nil
													repeats:YES] retain];
}



- (void)timerUpdate:(NSTimer*)theTimer {
	[stillCapturer captureScreenForRect:captureRect];

	[self addImageToMovie:[stillCapturer capturedImage]];
}

- (void)setAutoStopTime:(int)seconds {
	int s = seconds;
	if (s < 1) s = 1;
	if (s > 60) s = 60;
	
	autoStopAfterSeconds = seconds;
	autoStopAfterFrames = s * framesPerSecond;
}

- (void)startCapturingMovieForRect:(NSRect)rect {
	[startTime release];
	startTime = nil;
	isRecording = YES;
	framesCaptured = 0;
	
	if (nil == stillCapturer) stillCapturer = [[StillCapturer alloc] init];
	
	[mMovie release]; mMovie = nil;
	
	captureRect = rect;
	
	[self createTimer];
}

- (void)stopCapturingMovie {
	if (!isRecording) return;
	
	[self destroyTimer];
	
	double time = fabs([startTime timeIntervalSinceNow]);
	
	NSLog(@"captured %i frames in %f seconds.", framesCaptured, time);
	
	long timeElapsed = (long)time;
	
	NSNumber *scale = [mMovie attributeForKey:QTMovieTimeScaleAttribute];

	// set the duration
	[mMovie scaleSegment:QTMakeTimeRange(QTZeroTime, [mMovie duration])
			 newDuration:QTMakeTime(timeElapsed * [scale longValue], [scale longValue])];	
		
	[self saveToDesktop];
	
	isRecording = NO;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"CMSStoppedRecording" object:@""];
}



- (BOOL)isRecording {
	return isRecording;
}

- (int)framesPerSecond {
	return framesPerSecond;
}

- (void)setFramesPerSecond:(int)fps {
	if (isRecording) return;
	
	framesPerSecond = fps;
	if (framesPerSecond < 1) framesPerSecond = 1;
	if (framesPerSecond > 30) framesPerSecond = 30;
}


- (void)setMovie:(QTMovie *)movie {
    [movie retain];
    [mMovie release];
    mMovie = movie;
}

-(QTMovie *)movie { return mMovie; }



// Most of this method is from Apple.
- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)type error:(NSError **)outError {
    BOOL success = NO;
   
    // read the movie
    if ([QTMovie canInitWithURL:url]) {
            [self setMovie:((QTMovie *)[QTMovie movieWithURL:url error:nil])];
            success = (mMovie != nil);
    }

    return success;
}


@end

