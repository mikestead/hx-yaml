package yaml.schema;

import yaml.type.YOmap;
import yaml.type.YMerge;
import yaml.type.YTimestamp;
import yaml.type.YSet;
import yaml.type.YPairs;
import yaml.type.YInt;
import yaml.type.YNull;
import yaml.schema.MinimalSchema;
import yaml.type.YFloat;
import yaml.type.YBool;
import yaml.type.YBinary;
import yaml.Schema;

class SafeSchema extends Schema
{
    public function new()
	{
		super([new MinimalSchema()], 
			[new YBinary(), new YOmap(), new YPairs(), new YSet()], 
			[new YNull(), new YBool(), new YInt(), new YFloat(), new YTimestamp(), new YMerge()]);
	}
}
