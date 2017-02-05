package yaml.type;
import yaml.YamlType;

import massive.munit.Assert;

class YMergeTest
{
	public function new() {}

	@Test
    public function testShouldResolveMerge()
	{
		var type = new YMerge();
		Assert.areEqual("<<", type.resolve("<<"));

		try {
			type.resolve("");
			Assert.fail("Should not resolve merge on any value but '<<'");
		}
		catch(e:ResolveTypeException) {}
	}
}
