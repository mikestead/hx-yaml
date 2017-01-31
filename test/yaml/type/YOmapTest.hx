package yaml.type;

import yaml.YamlType;
import yaml.util.ObjectMap;
import massive.munit.Assert;

class YOmapTest
{
	var type:YOmap;

	@Before
	public function before()
	{
		type = new YOmap();
	}

	#if cpp
	@Ignore("CPP seems to be passing arrays by value(?) so comparison check fails")
	#end
	@Test
    public function shouldAllowValidOmap()
	{
		var value:Array<AnyObjectMap> = [map("key01", "value01"), map("key02", "value02")];
		shouldPass(value);

		var value:Array<AnyObjectMap> = [map("key01", null), map("key02", null)];
		shouldPass(value);
	}
	
	@Test
	public function shouldFailInvalidOmap()
	{
		var value:Array<AnyObjectMap> = [map("key01", "value01"), map("key01", "value02")];
		shouldFail(value);

		var m = map("key01", "value01");
		m.set("key02", "value02");
		var value:Array<AnyObjectMap> = [m, map("key03", "value03")];
		shouldFail(value);
	}

	function shouldPass(value:Array<AnyObjectMap>)
	{
		Assert.areEqual(value, type.resolve(value));
	}

	function shouldFail(value:Array<AnyObjectMap>)
	{
		try {
			type.resolve(value);
			Assert.fail("Expected failure of omap resolution but succeeded. " + value);
		}
		catch(e:ResolveTypeException) {}
	}

	function map(key:Dynamic, value:Dynamic):AnyObjectMap
	{
		var map = new AnyObjectMap();
		map.set(key, value);
		return map;
	}
}
