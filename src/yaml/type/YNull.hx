package yaml.type;

import yaml.util.StringMap;
import yaml.YamlType;

class YNull extends yaml.StringYamlType<Dynamic>
{
	static var YAML_NULL_MAP:StringMap<Bool> = {
		var hash = new StringMap<Bool>();
		hash.set('~', true);
		hash.set('null', true);
		hash.set('Null', true);
		hash.set('NULL', true);
		hash;
	};

	public function new()
	{
		super('tag:yaml.org,2002:null', {kind:"string"}, {kind:"null", defaultStyle:"lowercase"});
	}

	override public function resolve(object:String, ?usingMaps:Bool = true, ?explicit:Bool = false):Dynamic
	{
		return YAML_NULL_MAP.exists(object) ? null : cantResolveType();
	}
	
	override public function represent(object:Dynamic, ?style:String):String
	{
		return switch (style)
		{
			case "canonical": "~";
			case "lowercase": "null";
			case "uppercase": "NULL";
			case "camelcase": "Null";
			default: "~";
		}
	}
}
