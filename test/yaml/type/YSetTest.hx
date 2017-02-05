package yaml.type;

import yaml.YamlType;
import yaml.util.ObjectMap;
import massive.munit.Assert;

class YSetTest
{
	public function new() {}

	@Test
    public function testShouldOnlyAllowNullValuesInMaps()
	{
		var type = new YSet();
		var map = new AnyObjectMap();
		map.set("key", "value");

		try {
			type.resolve(map);
			Assert.fail("Expcted failure due to map having non-null value");
		}
		catch(e:ResolveTypeException) {
			Assert.isTrue(true);
		}
	}

	@Test
	public function testShouldAllowMapsWithNullValue()
	{
		var type = new YSet();
		var map = new AnyObjectMap();
		map.set("key", null);

		Assert.areEqual(map, type.resolve(map));

	}
}
