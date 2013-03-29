package yaml.type;

import yaml.YamlType;

class YString extends yaml.StringYamlType<String>
{
    public function new()
	{
		super('tag:yaml.org,2002:str', {kind:"string", skip:true}, {skip:true});
	}
}
