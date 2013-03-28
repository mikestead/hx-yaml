package yaml.type;
import yaml.YamlType;

import massive.munit.Assert;

class TMergeTest
{
	@Test
    public function shouldResolveMerge()
	{
		var type = new TMerge();
		Assert.areEqual("<<", type.resolve("<<"));
		
		try {
			type.resolve("");
			Assert.fail("Should not resolve merge on any value but '<<'");
		}
		catch(e:ResolveTypeException) {}
	}
}
