package yaml.type;

import yaml.util.ObjectMap;
import yaml.YamlType;

class YSet extends YamlType<Dynamic, Dynamic>
{
    public function new()
	{
		super('tag:yaml.org,2002:set', {kind:"object"}, {skip:true});
	}

	override public function resolve(object:Dynamic, ?usingMaps:Bool = true, ?explicit:Bool = false):Dynamic
	{
		// again this is just validation, not resolving anything.
		usingMaps ? validateSet(object) : validateObjectSet(object);
		return object;
	}
	
	function validateSet(object:AnyObjectMap)
	{
		for (key in object.keys())
			if (object.get(key) != null)
				cantResolveType();
	}
	
	function validateObjectSet(object:Dynamic)
	{
		for (key in Reflect.fields(object))
			if (Reflect.field(object, key) != null)
				cantResolveType();
	}
}
