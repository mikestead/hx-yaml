/*
Copyright (c) 2012 Massive Interactive

Permission is hereby granted, free of charge, to any person obtaining a copy of 
this software and associated documentation files (the "Software"), to deal in 
the Software without restriction, including without limitation the rights to 
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
of the Software, and to permit persons to whom the Software is furnished to do 
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all 
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
SOFTWARE.
*/

package yaml.util;

/**
Utility methods for working with dates
*/
class Dates
{
	#if (flash || js)
	
	static function getNativeDate():Dynamic
	{
		#if flash9
		return untyped __global__["Date"];
		#elseif flash
		return untyped _global["Date"];
		#elseif js
		return untyped __js__("Date");
		#end
		return null;
	}
	
	/**
	Converts a Date to UTC ISO-8601 compliant string.

	Example: 2012-06-20T12:11:08.188Z

	Currently only supported under JS, AS3 and AS2.
	
	@param date		the date to convert to utc iso string
	@return ISO-8601 compliant timestamp
	*/
	public static function toISOString(date:Date):String
	{
		var NativeDate = getNativeDate();
		var d = untyped __new__(NativeDate, date.getTime());

		return d.getUTCFullYear() + '-'
			+ StringTools.lpad("" + (d.getUTCMonth() + 1), "0", 2) + '-'
			+ StringTools.lpad("" + d.getUTCDate(), "0", 2) + 'T'
			+ StringTools.lpad("" + d.getUTCHours(), "0", 2) + ':'
			+ StringTools.lpad("" + d.getUTCMinutes(), "0", 2) + ':'
			+ StringTools.lpad("" + d.getUTCSeconds(), "0", 2) + '.'
			+ StringTools.rpad(("" + (Floats.round(d.getUTCMilliseconds()/1000, 3))).substr(2, 5), "0", 3)
			+ 'Z';
	}
	#end
}
