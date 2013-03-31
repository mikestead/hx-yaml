package yaml.type;

import yaml.util.ObjectMap;
import yaml.YamlType;
import Type;

class YPairs extends YamlType<Array<Array<Dynamic>>, Array<AnyObjectMap>>
{
    public function new()
	{
		super("tag:yaml.org,2002:pairs", {kind:"array"}, {skip:true});
	}

	override public function resolve(object:Array<AnyObjectMap>, ?explicit:Bool = false):Array<Array<Dynamic>>
	{
		var result:Array<Array<Dynamic>> = [];
		
		for (pair in object)
		{
			if (!Std.is(pair, AnyObjectMap))
				cantResolveType();

			var fieldCount = 0;
			var keyPair:Dynamic = null;
			for (key in pair.keys())
			{
				keyPair = key;
				if (fieldCount++ > 1) break;
			}

			if (fieldCount != 1) // must have one key
				cantResolveType();

			result.push([keyPair, pair.get(keyPair)]);
		}

		return result;
	}
}
