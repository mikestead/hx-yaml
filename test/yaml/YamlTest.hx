package yaml;

import yaml.util.ObjectMap;
import yaml.Renderer;
import yaml.Parser;
import massive.munit.Assert;

class YamlTest {
	var smallSample:String;
	var largeSample:String;

	@BeforeClass
	public function init() {
		smallSample = haxe.Resource.getString("small");
		largeSample = haxe.Resource.getString("large");
	}

	@TestDebug
	public function shouldParseYaml() {
		var time = haxe.Timer.stamp();
		//		var data:Dynamic = Yaml.parse(smallSample, Parser.options().useObjects());
		var data:Dynamic = Yaml.parse(largeSample, Parser.options().useObjects());
		trace((haxe.Timer.stamp() - time));

		#if sys
		Yaml.write("bin/test/output.yaml", data);
		#else
		trace(Yaml.render(data));
		#end
	}
}
