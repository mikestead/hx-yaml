package yaml.type;

import yaml.YamlType;
import massive.munit.Assert;

class YFloatTest
{
	var type:YFloat;

	@Before
    public function before()
	{
		type = new YFloat();
	}

	@Test
	public function shouldResolveFloat()
	{
		var const = 685230.15;
		
		var values = ["6.8523015e+5", "685.230_15e+03", "685_230.15", "190:20:30.15"];
		for (value in values)
			Assert.areEqual(const, type.resolve(value));
		
		Assert.areEqual(Math.NEGATIVE_INFINITY, type.resolve("-.inf"));
		Assert.areEqual(Math.POSITIVE_INFINITY, type.resolve(".inf"));
		Assert.isTrue(Math.isNaN(type.resolve(".NaN")));
	}

	@Test
	public function shouldRepresentFloat()
	{
		Assert.areEqual("685230.15", type.represent(685230.15));
		
		Assert.areEqual(".inf", type.represent(Math.POSITIVE_INFINITY, "lowercase"));
		Assert.areEqual(".INF", type.represent(Math.POSITIVE_INFINITY, "uppercase"));
		Assert.areEqual(".Inf", type.represent(Math.POSITIVE_INFINITY, "camelcase"));
		
		Assert.areEqual("-.inf", type.represent(Math.NEGATIVE_INFINITY, "lowercase"));
		Assert.areEqual("-.INF", type.represent(Math.NEGATIVE_INFINITY, "uppercase"));
		Assert.areEqual("-.Inf", type.represent(Math.NEGATIVE_INFINITY, "camelcase"));
		
		Assert.areEqual(".nan", type.represent(Math.NaN, "lowercase"));
		Assert.areEqual(".NAN", type.represent(Math.NaN, "uppercase"));
		Assert.areEqual(".NaN", type.represent(Math.NaN, "camelcase"));
	}
}
