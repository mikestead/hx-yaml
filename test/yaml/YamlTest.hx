package yaml;

import yaml.Renderer;
import yaml.Parser;
import massive.munit.Assert;

class YamlTest
{
	var sample:String;
	var smallSample:String;

	@BeforeClass
	public function init()
	{
		//		sample = haxe.Resource.getString("sample_yaml");
		smallSample = haxe.Resource.getString("ss");
	}

	@Test
	public function shouldParseYaml()
	{
		var data = cast Yaml.parse(smallSample);
		
		#if sys
		Yaml.write(data, "bin/test/output.yaml", new RenderOptions());
		#else
		trace(data);
		#end
	}
}
