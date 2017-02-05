package yaml.type;

import yaml.YamlType;
import massive.munit.Assert;

class YBoolTest
{
	var type:AnyYamlType;

	public function new() {}

	@Before
	public function setup()
	{
		type = new YBool();
	}

	@Test
	public function testShouldResolveExplicitValues()
	{
		var pos = ["true", "True", "TRUE", "y", "Y", "yes", "Yes", "YES", "on", "On", "ON"];
		for (value in pos)
			Assert.isTrue(type.resolve(value, true, true));

		var neg = ["n", "N", "no", "No", "NO", "false", "False", "FALSE", "off", "Off", "OFF"];
		for (value in neg)
			Assert.isFalse(type.resolve(value, true, true));
	}

	@Test
	public function testShouldResolveImplicitValues()
	{
		var pos = ["true", "True", "TRUE"];
		for (value in pos)
			Assert.isTrue(type.resolve(value, true, false));

		var neg = ["false", "False", "FALSE"];
		for (value in neg)
			Assert.isFalse(type.resolve(value, true, false));
	}

	@Test
	public function testShouldNotResolveExplicitValueWhenImplicit()
	{
		var values = ["y", "Y", "yes", "Yes", "YES", "on", "On", "ON", "n", "N", "no", "No", "NO", "off", "Off", "OFF"];
		while (values.length > 0)
		{
			try {
				type.resolve(values[0], false);
				Assert.fail("Should not have resolved type " + values[0]);
			}
			catch(e:ResolveTypeException) {
				values.pop();
			}
		}
		Assert.areEqual(0, values.length);
	}

	@Test
	public function testShouldRepresentValue()
	{
		Assert.areEqual(type.represent(true, "uppercase"), "TRUE");
		Assert.areEqual(type.represent(false, "uppercase"), "FALSE");

		Assert.areEqual(type.represent(true, "lowercase"), "true");
		Assert.areEqual(type.represent(false, "lowercase"), "false");

		Assert.areEqual(type.represent(true, "camelcase"), "True");
		Assert.areEqual(type.represent(false, "camelcase"), "False");
	}
}
