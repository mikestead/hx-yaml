package yaml.type;

import yaml.YamlType;

class TMap extends yaml.StringYamlType<StringMap<Dynamic>>
{
    public function new()
	{
		super('tag:yaml.org,2002:map', {kind:"object", skip:true}, {skip:true});
	}
}
