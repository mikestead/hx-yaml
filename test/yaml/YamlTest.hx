package yaml;

import yaml.util.MapWrapper;
import yaml.util.ObjectMap;
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
	
	function processMap<K, V>(map:Map<K, V>)
	{
		for (key in map.keys())
		{
			trace(key);
			trace(map.get(key));
		}
	}
	
	@TestDebug
	public function shouldParseYaml()
	{
//		var data = cast Yaml.parse(smallSample);
		var data:AnyObjectMap = cast Yaml.parse(smallSample, new ParserOptions(null, false));
		for (key in data.keys())
			trace(Type.getClassName(Type.getClass(key)) + "::" + key);
		
//		#if sys
//		Yaml.write("bin/test/output.yaml", data, new RenderOptions());
//		#else
		trace(Yaml.render(data, new RenderOptions(2, 1)));
//		#end
	}
}
