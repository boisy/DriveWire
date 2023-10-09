//--------------------------------------------------------------------------------------------------
//
//  Copyright (c) 2009-2021 Boisy G. Pitre
//
//  This source code and specific concepts contained herein are Confidential
//  Information and Property of Boisy G. Pitre.
//  Distribution is prohibited without written permission of Boisy G. Pitre.
//
//--------------------------------------------------------------------------------------------------


#import <Foundation/Foundation.h>

@interface NSString (Additions)

- (NSRange)rangeFromString:(NSString *)inString1
				  toString:(NSString *)inString2
				   options:(unsigned)inMask 
					 range:(NSRange)inSearchRange;

- (NSRange)rangeFromString:(NSString *)inString1
				  toString:(NSString *)inString2;

- (NSString *)replaceAllTextBetweenString:(NSString *)inString1 
								andString:(NSString *)inString2
						   fromDictionary:(NSDictionary *)inDict
								  options:(unsigned)inMask
									range:(NSRange)inSearchRange;

- (NSString *)replaceAllTextBetweenString:(NSString *)inString1 
								andString:(NSString *)inString2
						   fromDictionary:(NSDictionary *)inDict
								  options:(unsigned)inMask;

- (NSString *)replaceAllTextBetweenString:(NSString *)inString1 
								andString:(NSString *)inString2
						   fromDictionary:(NSDictionary *)inDict;

- (BOOL)hasCaseInsensitivePrefix:(NSString *)prefix;

- (BOOL)hasCaseInsensitiveSuffix:(NSString *)suffix;

- (BOOL)stringEndsWithString:(NSString *)s;

- (NSString *)capitalizedStringFirstWordOnly;

- (NSString *)camelCaseString;

//- (NSString *)uncapitalizedStringFirstWordOnly;

- (NSString *)stringByReplacingSpaceWithUnderscore;

- (NSString *)stringByAddingURLEscapesUsingEncoding:(CFStringEncodings)enc;

+ (NSString *)stringWithBytes:(const void *)bytes
					   length:(NSUInteger)length
					 encoding:(NSStringEncoding)encoding;

- (BOOL)stringContainsString:(NSString *)s;

- (BOOL)stringContainsCaseInsensitiveString:(NSString *)s;

- (BOOL)stringContainsCharactersFromString:(NSString *)s;

- (BOOL)stringContainsCharactersFromSet:(NSCharacterSet *)set;

//-(NSString *)stringByRemovingRichTextFromString:(NSString *)inputString

- (BOOL)stringBeginsWithTwoNumbers;

- (NSMutableArray *)splitLines;

- (NSString *)stringByRemovingWhitespaceCharacters;

- (NSString *)stringByRemovingNewline;

- (NSString *)stringByRemovingWhitespaceCharactersAndNewline;

- (NSString *)stringByRemovingCharactersFromSet:(NSCharacterSet *)set;

- (NSString *)bracketedStringWithLeftBracket:(NSString *)leftBracket 
								rightBracket:(NSString *)rightBracket 
							   caseSensitive:(BOOL)caseSensitive;

- (NSString *)addSpacesToStringWithInterval:(int)interval;

- (NSString *)addSpacesToStringWithInterval:(int)interval
					   removeOldWhitespaces:(BOOL)remove;

- (NSMutableString *)convertLineBreaksToMac;

@end

@interface NSMutableString (BGPMutableStringAdditions)

- (void)removeCharactersInSet:(NSCharacterSet *)set;

@end

@interface NSString (BGPRelativePath)

- (NSString *)absolutePathFromBaseDirPath:(NSString *)baseDirPath;
- (NSString *)relativePathFromBaseDirPath:(NSString *)baseDirPath;

@end

@interface NSString (BGPNonPrintable)

- (NSString *)stringByEscapingNonPrintableCharacters;

@end

@interface NSString (BGPStringConversions)

- (NSInteger)valueOfHexString;

- (NSInteger)valueOfBinaryString;

@end
