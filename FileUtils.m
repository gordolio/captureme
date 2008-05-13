
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

#import "FileUtils.h"


@implementation FileUtils

// returns YES if the file specified by path exists, NO otherwise
+ (BOOL)pathExists:(NSString *)aFilePath {
	NSFileManager *defaultMgr = [NSFileManager defaultManager]; 
	
	return [defaultMgr fileExistsAtPath:aFilePath];
}


// Returns the next available numerical name for passed path, ie, 
// pass it (@"/Users/ryan/Desktop/", and @"CM Capture".
+ (NSString*)incrementalNameForDirectoryPath:(NSString*)path andPrefix:(NSString *)prefix {
	
	if (![FileUtils pathExists:path]) return nil;
	
	NSFileManager * manager = [NSFileManager defaultManager];
	NSDirectoryEnumerator * dirEnumerator = [manager enumeratorAtPath:path];
	NSString * fileName;
	NSString * number;
	
	NSMutableDictionary * usedNumbers = [NSMutableDictionary dictionaryWithCapacity:4];
		
	int prefixLength = [prefix length];
	
	while (nil != (fileName = [dirEnumerator nextObject])) {
		if ([fileName hasPrefix:prefix]) {
			number = [[fileName substringFromIndex:prefixLength + 1] stringByDeletingPathExtension];
			[usedNumbers setValue:fileName forKey:number];
		}
	}
	
	int num = 1;
	BOOL foundSpace = NO;
	while (!foundSpace) {
		if (nil != [usedNumbers valueForKey:[NSString stringWithFormat:@"%d", num]]) {
			num++;			
		} else {
			foundSpace = YES;
		}
	}
	
	NSString * newPath = [NSString stringWithFormat:@"%@/%@ %d", path, prefix, num];	
	return newPath;
}


@end
