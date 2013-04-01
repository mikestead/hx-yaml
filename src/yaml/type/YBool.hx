package yaml.type;

import yaml.util.StringMap;
import yaml.YamlException;
import yaml.YamlType;

class YBool extends StringYamlType<Bool>
{
	static var YAML_IMPLICIT_BOOLEAN_MAP:StringMap<Bool> =
	{
		var hash = new StringMap<Bool>();
		hash.set("true", true);
		hash.set("True", true);
		hash.set("TRUE", true);
		hash.set("false", false);
		hash.set("False", false);
		hash.set("FALSE", false);
		hash;
	};

	static var YAML_EXPLICIT_BOOLEAN_MAP =
	{
		var hash = new StringMap<Bool>();
		hash.set("true", true);
		hash.set("True", true);
		hash.set("TRUE", true);
		hash.set("false", false);
		hash.set("False", false);
		hash.set("FALSE", false);
		hash.set("y", true);
		hash.set("Y", true);
		hash.set("yes", true);
		hash.set("Yes", true);
		hash.set("YES", true);
		hash.set("n", false);
		hash.set("N", false);
		hash.set("no", false);
		hash.set("No", false);
		hash.set("NO", false);
		hash.set("on", true);
		hash.set("On", true);
		hash.set("ON", true);
		hash.set("off", false);
		hash.set("Off", false);
		hash.set("OFF", false);
		hash;
	};
	
	public function new()
	{
		super('tag:yaml.org,2002:bool', {kind:"string"}, {kind:"boolean", defaultStyle:"lowercase"});
	}

	override public function resolve(object:String, ?usingMaps:Bool = true, ?explicit:Bool):Bool
	{
		if (explicit) 
		{
			if (YAML_EXPLICIT_BOOLEAN_MAP.exists(object))
			{
				return YAML_EXPLICIT_BOOLEAN_MAP.get(object);
			} 
			else 
			{
				return cantResolveType();
			}
		}
		else
		{
			if (YAML_IMPLICIT_BOOLEAN_MAP.exists(object))
			{
				return YAML_IMPLICIT_BOOLEAN_MAP.get(object);
			}
			else 
			{
				return cantResolveType();
			}
		}
	}

	override public function represent(object:Bool, ?style:String):String
	{
		return switch (style)
		{
			case "uppercase": object ? 'TRUE' : 'FALSE';
			case "lowercase": object ? 'true' : 'false';
			case "camelcase": object ? 'True' : 'False';
			default: 
				throw new YamlException("Style not supported: " + style);
				null;
		}
	}
}
