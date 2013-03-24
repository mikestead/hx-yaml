package yaml.schema;

import yaml.type.TOmap;
import yaml.type.TMerge;
import yaml.type.TTimestamp;
import yaml.type.TSet;
import yaml.type.TPairs;
import yaml.type.TInt;
import yaml.type.TNull;
import yaml.schema.MinimalSchema;
import yaml.type.TFloat;
import yaml.type.TBool;
import yaml.type.TBinary;
import yaml.Schema;

class SafeSchema extends Schema
{
    public function new()
	{
		super([new MinimalSchema()], 
			[new TBinary(), new TOmap(), new TPairs(), new TSet()], 
			[new TNull(), new TBool(), new TInt(), new TFloat(), new TTimestamp(), new TMerge()]);
	}
}
