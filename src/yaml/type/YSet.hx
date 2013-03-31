package yaml.type;

import yaml.util.ObjectMap;
import yaml.YamlType;

class YSet extends YamlType<AnyObjectMap, AnyObjectMap>
{
    public function new()
	{
		super('tag:yaml.org,2002:set', {kind:"object"}, {skip:true});
	}

	override public function resolve(object:AnyObjectMap, ?explicit:Bool = false):AnyObjectMap
	{
		// again this is just validation, not resolving anything.
		for (key in object.keys())
			if (object.get(key) != null)
				cantResolveType();
		
		return object;
	}
}
