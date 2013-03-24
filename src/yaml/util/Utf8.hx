package yaml.util;

class Utf8
{
	public static function substring(value:String, startIndex:Int, ?endIndex:Null<Int>):String
	{
		var size = haxe.Utf8.length(value);
		var pos = startIndex;
		var length = 0;
		
		if (endIndex == null)
		{
			length = size - pos;
		}
		else 
		{
			if (startIndex > endIndex)
			{
				pos = endIndex;
				endIndex = startIndex;
			}
			length = endIndex - pos;
		}
		
		return haxe.Utf8.sub(value, pos, length);
	}
}
