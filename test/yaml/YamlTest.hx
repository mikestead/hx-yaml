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
		var data:StringMap<Dynamic> = cast Yaml.parse(smallSample);
		
		for (key in data.keys())
			trace(key + "::" + data.get(key));
		
		trace(Yaml.render(data));

		//		trace(yam);
		//		var out = new Dumper().dump(yam, new DumperOptions());
		//		trace(out);

		//		var utf8 = new haxe.Utf8();
		//		utf8.addChar(0x2665);
		//		trace("A>>" + utf8.toString() + "<<");
		//		trace("B>>" + String.fromCharCode(0x2665) + "<<");
	}
}
