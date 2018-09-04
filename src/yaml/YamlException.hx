package yaml;

import haxe.PosInfos;

class YamlException
{
	public var name(get, null):String;
	function get_name():String { return name; }

	public var message(get, null):String;
	function get_message():String { return message; }

	public var cause(default, null):Dynamic;
	public var info(default, null):PosInfos;
	
    public function new(?message:String="", ?cause:Dynamic = null, ?info:PosInfos)
	{
		this.name = Type.getClassName(Type.getClass(this));
		this.message = message;
		this.cause = cause;
		this.info = info;
	}

	public function toString():String
	{
		var str:String = name + ": " + message;
		if (info != null)
			str += " at " + info.className + "#" + info.methodName + " (" + info.lineNumber + ")";
		return str;
	}
}
