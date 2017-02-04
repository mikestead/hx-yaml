package yaml.type;

import yaml.YamlType;
import yaml.util.ObjectMap;
import massive.munit.Assert;

class YPairsTest
{
	var type:YPairs;

	public function new() {}

	@Before
	public function setup()
	{
		type = new YPairs();
	}

	@Test
	public function testShouldAllowValidPair()
	{
		var value:Array<AnyObjectMap> = [map("key01", "value01"), map("key02", "value02")];
		shouldPass(value);

		var value:Array<AnyObjectMap> = [map("key01", null), map("key02", null)];
		shouldPass(value);

		var value:Array<AnyObjectMap> = [map("key01", "value01"), map("key01", "value02")];
		shouldPass(value);
	}

	@Test
	public function testShouldFailInvalidOmap()
	{
		var m = map("key01", "value01");
		m.set("key02", "value02");
		var value:Array<AnyObjectMap> = [m, map("key03", "value03")];
		shouldFail(value);
	}

	function shouldPass(value:Array<AnyObjectMap>)
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

	function shouldFail(value:Array<AnyObjectMap>)
	{
		try {
			type.resolve(value);
			Assert.fail("Expected failure of pairs resolution but succeeded. " + value);
		}
		catch(e:ResolveTypeException) {
			Assert.isTrue(true);
		}
	}

	function map(key:Dynamic, value:Dynamic):AnyObjectMap
	{
		var map = new AnyObjectMap();
		map.set(key, value);
		return map;
	}
}
