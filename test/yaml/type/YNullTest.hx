package yaml.type;

import yaml.YamlType;
import massive.munit.Assert;

class YNullTest
{
	var type:YNull;

	public function new() {}

	@Before
    public function setup()
	{
		type = new YNull();
	}

	@Test
	public function testShouldResolveNull()
	{
		Assert.isNull(type.resolve("null"));
		Assert.isNull(type.resolve("Null"));
		Assert.isNull(type.resolve("NULL"));
		Assert.isNull(type.resolve("~"));

		try {
			type.resolve("some value");
			Assert.fail("Should not resolve non-null value");
		}
		catch(e:ResolveTypeException) {
		}
	}

	@Test
	public function testShouldRepresentNull()
	{
		Assert.areEqual("~", type.represent(null, "canonical"));
		Assert.areEqual("null", type.represent(null, "lowercase"));
		Assert.areEqual("NULL", type.represent(null, "uppercase"));
		Assert.areEqual("Null", type.represent(null, "camelcase"));
	}
}
