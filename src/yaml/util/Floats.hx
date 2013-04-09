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
Utility methods for working with float values.
*/
class Floats
{
	/**
	Returns the string representation of a float.
	
	Under cpp will convert large floats with a positive exponent (eg date.getTime()) to a decimal string.
		e.g 1.347420344e+12 -> 1347420344000
	*/
	public static function toString(value:Float):String
	{
		#if cpp
		var str = Std.string(value);
		if (str.indexOf("e+") != -1)
		{
			var parts = str.split(".");
			var exp = parts[1].split("e+");
			str = parts[0] + StringTools.rpad(exp[0], "0", Std.parseInt(exp[1]));
		}
		return str;
		#else
		return Std.string(value);
		#end
	}

	/**
	Rounds a value to a specific decimal precision
	
	Example:
	<pre>
	FloatUtil.round(1.6666667 3);//returns 1.667;
	</pre>

	@param value 		value to round
	@param precision 	precision in decimals
	@return the rounded value
	*/
	static public function round(value:Float, precision:Int):Float
	{
		value = value * Math.pow(10, precision);
		return Math.round(value) / Math.pow(10, precision);
	}
}
