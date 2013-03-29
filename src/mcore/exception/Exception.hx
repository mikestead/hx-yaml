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

package mcore.exception;

import haxe.PosInfos;
/**
The base class for other exceptions.

When an error is detected, or a platform specific exception is caught, an instance
of Exception can be raised better describing the issue. This allows consistent
and targeted capturing of exceptions further down the call stack.

<pre>
try
{
	throw new Exception("something bad happened");
}
catch(e:Exception)
{
	trace(e.toString());
	//outputs "Exception: something bad happened at foo.Bar#doSomething(123)"
}
</pre>
*/
class Exception
{
	public var name(get_name, null):String;
	function get_name():String { return name; }

	public var message(get_message, null):String;
	function get_message():String { return message; }

	public var cause(default, null):Dynamic;
	public var info(default, null):PosInfos;

	/**
	@param message  an optional message helping to describe the exception
	@param cause    the exception which caused this one, if any. May be a native platform exception.
	*/
	public function new(?message:String="", ?cause:Dynamic = null, ?info:PosInfos)
	{
		this.name = Type.getClassName(Type.getClass(this));
		this.message = message;
		this.cause = cause;
		this.info = info;
	}

	/**
	Returns a string representation of this exception.
	
	Format: 
	<pre>
	<type>: <message> at <className>#<methodName> (<lineNumber>) Caused by: <cause>
	</pre>
   
	@return string representation of exception adhering to format above
	*/
	public function toString():String
	{
		var str:String = name + ": " + message;
		if (info != null)
		{
			str += " at " + info.className + "#" + info.methodName + " (" + info.lineNumber + ")";
		}
		if (cause != null)
		{
			str += "\n\t Caused by: " + getStackTrace(cause);
		}

		return str;
	}

	/**
	Returns a formatted list of the current exception stack

	@param source		an originating cause (such as a native flash error)
	@return formatting string of stack items 
	*/
	public static function getStackTrace(source:Dynamic):String
	{
		#if cpp
		return "getStackTrace not supported in cpp, see: http://code.google.com/p/hxcpp/issues/detail?id=195";
		#else
		var s = "";

		#if flash9
		if (Std.is(source, flash.errors.Error))
			s =  source.getStackTrace();
		#end
		
		if(s != "") return s;

		#if haxe3
		var stack:Array<haxe.CallStack.StackItem> = haxe.CallStack.exceptionStack();
		#else
		var stack:Array<haxe.CallStack.StackItem> = haxe.Stack.exceptionStack();
		#end

		while (stack.length > 0)
		{
			switch(stack.shift())
			{
				case FilePos(_, file, line): s += "\tat " + file + " (" + line + ")\n";
				case Module(_):
				case Method(classname, method): s += "\tat " + classname + "#" + method + "\n";
				case Lambda(_):
				case CFunction:
			}
		}
		return s;
		#end
	}
}
