package yaml.schema;

import yaml.Schema;

class DefaultSchema extends Schema
{
    public function new()
	{
		super([new SafeSchema()], null);//[new TRegex(), new TFunction()]);
	}
}
