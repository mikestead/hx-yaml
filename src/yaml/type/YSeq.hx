package yaml.type;

import yaml.YamlType;

class YSeq extends StringYamlType<Array<Dynamic>>
{
    public function new()
	{
		super('tag:yaml.org,2002:seq', {kind:"array", skip:true}, {skip:true});
	}
}
