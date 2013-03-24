package yaml.schema;

import yaml.type.TSeq;
import yaml.type.TMap;
import yaml.type.TString;
import yaml.Schema;

class MinimalSchema extends Schema
{
    public function new()
	{
		super([], [new TString(), new TSeq(), new TMap()]);
	}
}
