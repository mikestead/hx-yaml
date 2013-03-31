package yaml.type;

import yaml.YamlType;
import yaml.util.StringMap;
import massive.munit.Assert;

class YOmapTest
{
	var type:YOmap;

	@Before
	public function before()
	{
		type = new YOmap();
	}

	@Test
    public function shouldAllowValidOmap()
	{
		var value = [map("key01", "value01"), map("key02", "value02")];
		shouldPass(value);

		var value = [map("key01", null), map("key02", null)];
		shouldPass(value);
	}
	
	@Test
	public function shouldFailInvalidOmap()
	{
		var value = [map("key01", "value01"), map("key01", "value02")];
		shouldFail(value);

		var m = map("key01", "value01");
		m.set("key02", "value02");
		var value = [m, map("key03", "value03")];
		shouldFail(value);
	}

	function shouldPass(value:Array<StringMap<Dynamic>>)
	{
		Assert.areEqual(value, type.resolve(value));
	}

	function shouldFail(value:Array<StringMap<Dynamic>>)
	{
		try {
			type.resolve(value);
			Assert.fail("Expected failure of omap resolution but succeeded. " + value);
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
