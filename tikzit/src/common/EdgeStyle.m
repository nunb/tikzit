//
//  EdgeStyle.m
//  TikZiT
//  
//  Copyright 2011 Aleks Kissinger. All rights reserved.
//  
//  
//  This file is part of TikZiT.
//  
//  TikZiT is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//  
//  TikZiT is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//  
//  You should have received a copy of the GNU General Public License
//  along with TikZiT.  If not, see <http://www.gnu.org/licenses/>.
//  

#import "EdgeStyle.h"

@implementation EdgeStyle

+ (void)initialize {
	[self setKeys:[NSArray arrayWithObjects:
				@"tailStyle",
				@"headStyle",
				@"decorationStyle",
				@"thickness",
				@"colorRGB.red",
				@"colorRGB.blue",
				@"colorRGB.green",
				@"name",
				nil]
          triggerChangeNotificationsForDependentKey:@"tikz"];
	[self setKeys:[NSArray arrayWithObjects:
				@"colorRGB.name",
				nil]
          triggerChangeNotificationsForDependentKey:@"colorIsKnown"];
}

- (id)initWithName:(NSString*)nm {
    self = [super initWithNotificationName:@"EdgeStylePropertyChanged"];

	if (self != nil) {
		headStyle = AH_None;
		tailStyle = AH_None;
		decorationStyle = ED_None;
		colorRGB = [[ColorRGB alloc] initWithRed:0 green:0 blue:0];
		name = nm;
		category = nil;
		thickness = 1.0f;
	}

    return self;
}

- (id)init {
	self = [self initWithName:@"new"];
	return self;
}

- (id)copyWithZone:(NSZone*)zone {
	EdgeStyle *style = [[EdgeStyle allocWithZone:zone] init];
	[style setName:[self name]];
	[style setCategory:[self category]];
	[style setHeadStyle:[self headStyle]];
	[style setTailStyle:[self tailStyle]];
	[style setDecorationStyle:[self decorationStyle]];
	[style setThickness:[self thickness]];
	[style setColorRGB:[self colorRGB]];
	return style;
}

- (void)dealloc {
#if ! __has_feature(objc_arc)
    [name release];
    [category release];
    [colorRGB release];
    [super dealloc];
#endif
}

- (NSString*) description {
	return [NSString stringWithFormat:@"Edge style \"%@\"", name];
}

- (void) updateFromStyle:(EdgeStyle*)style {
	[self setName:[style name]];
	[self setCategory:[style category]];
	[self setHeadStyle:[style headStyle]];
	[self setTailStyle:[style tailStyle]];
	[self setDecorationStyle:[style decorationStyle]];
	[self setThickness:[style thickness]];
	[self setColorRGB:[style colorRGB]];
}

+ (EdgeStyle*)defaultEdgeStyleWithName:(NSString*)nm {
#if __has_feature(objc_arc)
    return [[EdgeStyle alloc] initWithName:nm];
#else
	return [[[EdgeStyle alloc] initWithName:nm] autorelease];
#endif
}

- (NSString*)name { return name; }
- (void)setName:(NSString *)s {
	if (name != s) {
		NSString *oldValue = name;
		name = [s copy];
		[self postPropertyChanged:@"name" oldValue:oldValue];
#if ! __has_feature(objc_arc)
		[oldValue release];
#endif
	}
}

- (ArrowHeadStyle)headStyle { return headStyle; }
- (void)setHeadStyle:(ArrowHeadStyle)s {
	ArrowHeadStyle oldValue = headStyle;
	headStyle = s;
	[self postPropertyChanged:@"headStyle" oldValue:[NSNumber numberWithInt:oldValue]];
}

- (ArrowHeadStyle)tailStyle { return tailStyle; }
- (void)setTailStyle:(ArrowHeadStyle)s {
	ArrowHeadStyle oldValue = tailStyle;
	tailStyle = s;
	[self postPropertyChanged:@"tailStyle" oldValue:[NSNumber numberWithInt:oldValue]];
}

- (EdgeDectorationStyle)decorationStyle { return decorationStyle; }
- (void)setDecorationStyle:(EdgeDectorationStyle)s {
	EdgeDectorationStyle oldValue = decorationStyle;
	decorationStyle = s;
	[self postPropertyChanged:@"decorationStyle" oldValue:[NSNumber numberWithInt:oldValue]];
}
- (float)thickness { return thickness; }
- (void)setThickness:(float)s {
	float oldValue = thickness;
	thickness = s;
	[self postPropertyChanged:@"thickness" oldValue:[NSNumber numberWithFloat:oldValue]];
}

- (NSString*)category {
	return category;
}

- (void)setCategory:(NSString *)s {
	if (category != s) {
		NSString *oldValue = category;
		category = [s copy];
		[self postPropertyChanged:@"category" oldValue:oldValue];
#if ! __has_feature(objc_arc)
        [oldValue release];
#endif
    }
}

- (ColorRGB*)colorRGB {
	return colorRGB;
}

- (void)setColorRGB:(ColorRGB*)c {
	if (colorRGB != c) {
		ColorRGB *oldValue = colorRGB;
		colorRGB = [c copy];
		[self postPropertyChanged:@"colorRGB" oldValue:oldValue];
#if ! __has_feature(objc_arc)
        [oldValue release];
#endif
    }
}

- (NSString*)tikz {
	NSMutableString *buf = [NSMutableString stringWithFormat:@"\\tikzstyle{%@}=[", name];

	NSString *colorName = [colorRGB name];
	if (colorName == nil)
		colorName = [colorRGB hexName];

	if (tailStyle == AH_Plain)
		[buf appendString:@"<"];
	else if (tailStyle == AH_Latex)
		[buf appendString:@"latex"];

	[buf appendString:@"-"];

	if (headStyle == AH_Plain)
		[buf appendString:@">"];
	else if (headStyle == AH_Latex)
		[buf appendString:@"latex"];

    if(colorName != nil){
        [buf appendString:@",draw="];
        [buf appendString:colorName];
    }
        
	if (decorationStyle != ED_None) {
		[buf appendString:@",postaction={decorate},decoration={markings,mark="];
		if (decorationStyle == ED_Arrow)
			[buf appendString:@"at position .5 with {\\arrow{>}}"];
		else if (decorationStyle == ED_Tick)
			[buf appendString:@"at position .5 with {\\draw (0,-0.1) -- (0,0.1);}"];
		[buf appendString:@"}"];
	}

	if (thickness != 1.0f) {
		[buf appendFormat:@",line width=%.3f", thickness];
	}

	[buf appendString:@"]"];
	return buf;
}

@end

// vi:ft=objc:ts=4:noet:sts=4:sw=4
