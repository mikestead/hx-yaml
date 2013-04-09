package;
import mtask.target.HaxeLib;

class Build extends mtask.core.BuildBase
{
	public function new()
	{
		super();
	}

	@target function haxelib(t:HaxeLib)
	{
		t.description = "A cross platform YAML 1.2 parser and renderer for Haxe.";
		t.url = "https://github.com/mikestead/hx-yaml";
		t.license = HaxeLibLicense.MIT;
		t.versionDescription = "Move all util classes into yaml.util package.";
		t.username = "mikestead";
		
		t.addTag("cross");
		t.addTag("utility");

		t.beforeCompile = function(path)
		{
			cp("src/*", path);
		}
	}

	@task function test()
	{
		cmd("haxelib", ["run", "munit", "test", "-coverage"]);
	}

	@task function release()
	{
		invoke("test");
		invoke("build haxelib");
	}
}
