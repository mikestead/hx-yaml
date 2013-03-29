package yaml.type;

import haxe.io.Bytes;
import massive.munit.Assert;

class YBinaryTest
{
	@Test
	public function shouldResolveAndRepresentBinary()
	{
		var type = new YBinary();
		var data:Bytes = cast type.resolve(createValue());
		Assert.areEqual(createValue(), type.represent(data));
	}

	function createValue()
	{
		return "R0lGODlhDAAMAIQAAP//9/X17unp5WZmZgAAAOfn515eXvPz7Y6OjuDg4J+fn5OTk6enp56enmlpaWNjY6Ojo4SEhP/++f/++f/++f/++f/++f/++f/++f/++f/++f/++f/++f/++f/++f/++SH+Dk1hZGUgd2l0aCBHSU1QACwAAAAADAAMAAAFLCAgjoEwnuNAFOhpEMTRiggcz4BNJHrv/zCFcLiwMWYNG84BwwEeECcgggoBADs=";
	}
}
