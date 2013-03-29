package yaml.schema;

import yaml.type.YSeq;
import yaml.type.YMap;
import yaml.type.YString;
import yaml.Schema;

class MinimalSchema extends Schema
{
    public function new()
	{
		super([], [new YString(), new YSeq(), new YMap()]);
	}
}
