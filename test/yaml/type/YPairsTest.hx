package yaml.type;

import yaml.YamlType;
import massive.munit.Assert;

class YPairsTest
{
	var type:YPairs;

	@Before
	public function before()
	{
		type = new YPairs();
	}

	@Test
	public function shouldAllowValidPair()
	{
		var value = [map("key01", "value01"), map("key02", "value02")];
		shouldPass(value);

		var value = [map("key01", null), map("key02", null)];
		shouldPass(value);

		var value = [map("key01", "value01"), map("key01", "value02")];
		shouldPass(value);
	}

	@Test
	public function shouldFailInvalidOmap()
	{
		var m = map("key01", "value01");
		m.set("key02", "value02");
		var value = [m, map("key03", "value03")];
		shouldFail(value);
	}

	function shouldPass(value:Array<StringMap<Dynamic>>)
	{
		var result = type.resolve(value);
		Assert.areEqual(value.length, result.length);
		
		for (i in 0...value.length)
		{
			var key = null;
			for (k in value[i].keys())
				key = k;
			
			Assert.areEqual(result[i][0], key);
			Assert.areEqual(result[i][1], value[i].get(key));
		}
	}

	function shouldFail(value:Array<StringMap<Dynamic>>)
	{
		try {
			type.resolve(value);
			Assert.fail("Expected failure of pairs resolution but succeeded. " + value);
		}
		catch(e:ResolveTypeException) {}
	}

	function map(key:String, value:String)
	{
		var map = new StringMap();
		map.set(key, value);
		return map;
	}
}
