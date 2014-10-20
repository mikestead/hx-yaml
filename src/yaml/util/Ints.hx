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
Utility methods for working with int values.
*/
class Ints
{
	// Base used for toString/parseInt conversions. Supporting base 2 to 36 for now as common standard.
	static var BASE = "0123456789abcdefghijklmnopqrstuvwxyz";

	/**
	Returns the string representation of an integer value based on an optional radix (base).
	
	A default base of 10 is used if none is supplied.
	
	A base below 2 or above 36 will cause an exception.
	
	@param  value   The integer value to return the string representation of.
	@param  radix   An integer between 2 and 36 to be used as the base for conversion. Defaults to 10.
	@return The string representation of the integer at the defined radix.
	*/
	public static function toString(value:Int, ?radix:Int = 10):String
	{
		if (radix < 2 || radix > BASE.length)
			throw "Unsupported radix " + radix;

		#if (js || flash)
		
		return untyped value.toString(radix);
		
		#else 

		if (radix == 10) return Std.string(value);
		else if (value == 0) return '0';
		else // do the conversion ourselves
		{
			var sign = "";
			if (value < 0)
			{
				sign = '-';
				value = -value;
			}

			var result = '';
			while (value > 0)
			{
				result = BASE.charAt(value % radix) + result;
				value = Std.int(value / radix);
			}

			return sign + result;
		}

		#end
	}

	/**
	Parses a string and returns the decimal integer value it represents or `null` if no value could be parsed.
	
	An optional radix can be supplied to indicate the base the value should be parsed under.
	If no base is supplied a base of 10 will be assumed, unless the value begins with '0x', in which case
	a base of 16 (hex) is assumed.
	
	Parsing continues until complete or an invalid char is found. In that case the value parsed up until that point 
	is returned. e.g. `parseInt("44dae", 10)` returns `44`.
	
	The reason for returning `null` instead of `Math.NaN` when parsing fails completely is that NaN is a Float which 
	would force the return type to also be Float. This would mean `var a:Int = parseInt(value)` would become invalid,
	which is unintuitive. A return type of Dynamic would fix this on most systems, but not flash (avm2) which
	will auto cast the Float to an Int meaning Math.isNaN test would always fail.
	
	@param  value   The value to parse into an integer
	@param  radix   The radix to base the conversion on. Default is 16 for string starting with '0x' otherwise 10.
	@return The decimal integer value which the supplied string represents, or null if it could not be parsed.
	*/
	public static function parseInt(value:String, ?radix:Null<Int>):Null<Int>
	{
		if (radix != null && (radix < 2 || radix > BASE.length))
			throw "Unsupported radix " + radix;

		#if js
		
		var v = untyped __js__("parseInt")(value, radix);
		return (untyped __js__("isNaN")(v)) ? null : v;
		
		#elseif flash9
		
		if (radix == null) radix = 0;
		var v = untyped __global__["parseInt"](value, radix);
		return (untyped __global__["isNaN"](v)) ? null : v;
		
		#elseif flash8
		
		var v = _global["parseInt"](value, radix);
		return _global["isNaN"](v) ? null : v;
		
		#else // do the conversion ourselves

		value = StringTools.trim(value).toLowerCase();

		if (value.length == 0)
			return null;

		var s = 0;
		var neg = false;
		if (value.indexOf("-") == 0)
		{
			neg = true;
			s = 1;
		}
		else if (value.indexOf("+") == 0)
		{
			s = 1;
		}

		if (s == 1 && value.length == 1)
			return null;

		var j = value.indexOf("0x");
		if ((j == 0 || (j == 1 && s == 1)) && (radix == null || radix == 16))
		{
			s += 2;
			if (radix == null) radix = 16;
		}
		else if (radix == null)
		{
			radix = 10;
		}

		var result = 0;
		for (i in s...value.length)
		{
			var x = BASE.indexOf(value.charAt(i));
			if (x == -1 || x >= radix)
			{
				if (i == s) return null;
				else return neg ? -result : result;
			}
			result = (result * radix) + x;
		}

		return neg ? -result : result;
		#end
	}
}
