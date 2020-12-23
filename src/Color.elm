module Color exposing (..)

import Element

mistyRose = Element.rgba255 241 222 222
heliotropeGray = Element.rgba255 187 172 193
oldLavender = Element.rgba255 128 114 123
artichoke = Element.rgba255 144 149 128
ebony = Element.rgba255 84 86 67
white = Element.rgb255 255 255 255
black = Element.rgb255 0 0 0

mistyRoseHighlighted = mistyRose 0.5
mistyRoseRegular = mistyRose 1.0
heliotropeGrayHighlighted = heliotropeGray 0.5
heliotropeGrayRegular = heliotropeGray 1.0
oldLavenderHighlighted = oldLavender 0.5
oldLavenderRegular = oldLavender 1.0
artichokeHighlighted = artichoke 0.5
artichokeRegular = artichoke 1.0
ebonyHighlighted = ebony 0.5
ebonyRegular = ebony 1.0

gray = Element.rgb255 238 238 238
thistle = Element.rgb255 216 191 216
indianred = Element.rgb255 205 92 92