//
//  MMElement.h
//  MMMarkdown
//
//  Copyright (c) 2012 Matt Diephouse.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import <Foundation/Foundation.h>


typedef enum
{
    MMElementTypeNone = 0,
    MMElementTypeHeader = 1,
    MMElementTypeParagraph = 2,
    MMElementTypeBlockquote = 3,
    MMElementTypeNumberedList = 4,
    MMElementTypeBulletedList = 5,
    MMElementTypeListItem = 6,
    MMElementTypeCodeBlock = 7,
    MMElementTypeHorizontalRule = 8,
    MMElementTypeHTML = 9,
    MMElementTypeLineBreak = 10,
    MMElementTypeStrikethrough = 11,
    MMElementTypeStrong = 12,
    MMElementTypeEm = 13,
    MMElementTypeCodeSpan = 14,
    MMElementTypeImage = 15,
    MMElementTypeLink = 16,
    MMElementTypeMailTo = 17,
    MMElementTypeDefinition = 18,
    MMElementTypeEntity = 19,
    MMElementTypeTable = 20,
    MMElementTypeTableHeader = 21,
    MMElementTypeTableHeaderCell = 22,
    MMElementTypeTableRow = 23,
    MMElementTypeTableRowCell = 24,
} MMElementType;

typedef NS_ENUM(NSInteger, MMTableCellAlignment)
{
    MMTableCellAlignmentNone,
    MMTableCellAlignmentLeft,
    MMTableCellAlignmentCenter,
    MMTableCellAlignmentRight,
};

@interface RCMMElement : NSObject

@property (assign, nonatomic) NSRange        range;
@property (assign, nonatomic) MMElementType  type;
@property (copy,   nonatomic) NSArray       *innerRanges;

@property (assign, nonatomic) MMTableCellAlignment alignment;
@property (assign, nonatomic) NSUInteger     level;
@property (copy,   nonatomic) NSString      *href;
@property (copy,   nonatomic) NSString      *title;
@property (copy,   nonatomic) NSString      *identifier;
@property (copy,   nonatomic) NSString      *stringValue;

@property (assign, nonatomic) RCMMElement *parent;
@property (copy,   nonatomic) NSArray   *children;

@property (copy,   nonatomic) NSString  *language;

- (void)addInnerRange:(NSRange)aRange;
- (void)removeLastInnerRange;

- (void)addChild:(RCMMElement *)aChild;
- (void)removeChild:(RCMMElement *)aChild;
- (RCMMElement *)removeLastChild;

@end
