package yaml.type;

import yaml.util.StringMap;
import yaml.util.ObjectMap;
import Type;

class YOmap extends yaml.YamlType<Array<Dynamic>, Array<Dynamic>>
{
    public function new()
	{
		super("tag:yaml.org,2002:omap", {kind:"array"}, {skip:true});
	}

	// For omap this method is only doing a validation that no duplicates are present and that
	// each pair has only one key. It's not really 'resolving' the value...
	override public function resolve(object:Array<Dynamic>, ?usingMaps:Bool = true, ?explicit:Bool = false):Array<Dynamic>
	{
		usingMaps ? validateOMap(cast object) : validateObjectOMap(object);
		return object;
	}
	
	function validateOMap(object:Array<AnyObjectMap>)
	{
		var objectKeys = new ObjectMap<Dynamic, Dynamic>();
		for (pair in object)
		{
			var pairHasKey = false;
			var pairKey:Dynamic = null;
			
			if (!Std.is(pair, AnyObjectMap))
				cantResolveType();
			
			for (key in pair.keys())
			{
				if (pairKey == null) pairKey = key;
				else cantResolveType(); // can only have one key
			}
	
			if (pairKey == null) // must have a key
				cantResolveType();
	
			if (objectKeys.exists(pairKey))
				cantResolveType(); // no duplicate keys allowed
			else
				objectKeys.set(pairKey, null);
		}

		return object;
	}

	function validateObjectOMap(object:Array<Dynamic>)
	{
		var objectKeys = new StringMap<Dynamic>();
		for (pair in object)
		{
			var pairHasKey = false;
			var pairKey:String = null;

			if (Type.typeof(pair) != ValueType.TObject)
				cantResolveType();
			
			for (key in Reflect.fields(pair))
			{
				if (pairKey == null) pairKey = key;
				else cantResolveType(); // can only have one key
			}

			if (pairKey == null) // must have a key
				cantResolveType();

			
			if (objectKeys.exists(pairKey)) cantResolveType(); // no duplicate keys allowed
			else objectKeys.set(pairKey, null);
		}
	}
}
