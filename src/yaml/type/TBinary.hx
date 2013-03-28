package yaml.type;

import haxe.io.Bytes;
import yaml.YamlType;
import mcore.crypto.Base64;

class TBinary extends yaml.StringYamlType<Bytes>
{
	static var base64 = new Base64();

	public function new()
	{
		super('tag:yaml.org,2002:binary', {kind:"string"}, {kind:"object", instanceOf:Bytes});
	}

	override public function resolve(object:String, ?explicit:Bool):Bytes
	{
		try
		{
			#if sys
			object = haxe.Utf8.encode(object);
			#end
			return base64.decodeBytes(Bytes.ofString(object));
		}
		catch(e:Dynamic)
		{
			return cantResolveType();
		}
	}

	override public function represent(object:Bytes, ?style:String):String
	{
		try
		{
			var value = base64.encodeBytes(object);
			#if sys
			value = haxe.Utf8.encode(value);
			#end
			return value;
		}
		catch(e:Dynamic)
		{
			return cantRepresentType();
		}
	}
}
