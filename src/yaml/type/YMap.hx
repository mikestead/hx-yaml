package yaml.type;

import yaml.util.ObjectMap;
import yaml.YamlType;

class YMap extends yaml.StringYamlType<Dynamic>
{
    public function new()
	{
		super('tag:yaml.org,2002:map', {kind:"object", skip:true}, {skip:true});
	}
}
