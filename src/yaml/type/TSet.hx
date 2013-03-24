package yaml.type;

import yaml.YamlType;

class TSet extends YamlType<StringMap<Dynamic>, StringMap<Dynamic>>
{
    public function new()
	{
		super('tag:yaml.org,2002:set', {kind:"object"}, {skip:true});
	}

	override public function resolve(object:StringMap<Dynamic>, ?explicit:Bool = false):StringMap<Dynamic>
	{
		for (key in object.keys())
			if (object.get(key) != null)
				cantResolveType();
		
//		// again this is just validation, not resolving anything.
//		for (key in Reflect.fields(object))
//			if (Reflect.field(object, key) != null)
//				cantResolveType();
		
		return object;
	}
}
