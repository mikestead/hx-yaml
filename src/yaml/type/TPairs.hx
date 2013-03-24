package yaml.type;

import yaml.YamlType;
import Type;

class TPairs extends YamlType<Array<Array<Dynamic>>,Array<StringMap<Dynamic>>>
{
    public function new()
	{
		super("tag:yaml.org,2002:pairs", {kind:"array"}, {skip:true});
	}

	override public function resolve(object:Array<StringMap<Dynamic>>, ?explicit:Bool = false):Array<Array<Dynamic>>
	{
		var result:Array<Array<Dynamic>> = [];
		
		for (pair in object)
		{
//			if (Type.typeof(pair) != ValueType.TObject)
			if (!Std.is(pair, StringMap))
				cantResolveType();

			var fieldCount = 0;
			var keyPair:String = null;
//			for (key in Reflect.fields(pair))
			for (key in pair.keys())
			{
				keyPair = key;
				if (fieldCount++ > 1) break;
			}

			if (fieldCount != 1) // must have one key
				cantResolveType();

//			result.push([keyPair, Reflect.field(pair, keyPair)]);
			result.push([keyPair, pair.get(keyPair)]);
		}

		return result;
	}
}
