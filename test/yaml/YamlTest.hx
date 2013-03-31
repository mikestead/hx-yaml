package yaml;

import yaml.util.ObjectMap;
import yaml.Renderer;
import yaml.Parser;
import massive.munit.Assert;

class YamlTest
{
	var smallSample:String;
	var largeSample:String;

	@BeforeClass
	public function init()
	{
		smallSample = haxe.Resource.getString("small");
		largeSample = haxe.Resource.getString("large");
	}
	
	@TestDebug
	public function shouldParseYaml()
	{
		var time = haxe.Timer.stamp();
//		var data = cast Yaml.parse(smallSample, new ParserOptions(null, false));
		var data = cast Yaml.parse(largeSample, new ParserOptions(null, false));
		trace((haxe.Timer.stamp() - time));
		
		#if sys
		Yaml.write("bin/test/output.yaml", data, new RenderOptions(2, 2));
		#else
		trace(Yaml.render(data, new RenderOptions(2, 2)));
		#end
	}
}
