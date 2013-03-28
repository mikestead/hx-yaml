package yaml.type;

import mcore.util.Iterables;
import Type;

class TOmap extends yaml.YamlType<Array<StringMap<Dynamic>>, Array<StringMap<Dynamic>>>
{
    public function new()
	{
		super("tag:yaml.org,2002:omap", {kind:"array"}, {skip:true});
	}

	// For omap this method is only doing a validation that no duplicates are present and that
	// each pair has only one key. It's not really 'resolving' the value...
	override public function resolve(object:Array<StringMap<Dynamic>>, ?explicit:Bool = false):Array<StringMap<Dynamic>>
	{
		var objectKeys = new StringMap();
		
		for (pair in object)
		{
			var pairHasKey = false;
			var pairKey:String = null;
			
			if (!Std.is(pair, StringMap))
			{
				cantResolveType();
			}
			
			for (key in pair.keys())
			{
				if (pairKey == null)
				{
					pairKey = key;
				}
				else
				{
					cantResolveType(); // can only have one key
				}
			}
	
			if (pairKey == null) // must have a key
			{
				cantResolveType();
			}
	
			if (objectKeys.exists(pairKey))
				cantResolveType(); // no duplicate keys allowed
			else
				objectKeys.set(pairKey, null);
		}

		return object;
	}
}
