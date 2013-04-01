package yaml.type;

import yaml.YamlType;

class YMerge extends yaml.StringYamlType<String>
{
    public function new()
	{
		super('tag:yaml.org,2002:merge', {kind:"string"}, {skip:true});
	}

	override public function resolve(object:String, ?usingMaps:Bool = true, ?explicit:Bool):String
	{
		return ('<<' == object) ? object : cantResolveType();
	}

	override public function represent(object:String, ?style:String):String
	{
		return null;
	}
}
