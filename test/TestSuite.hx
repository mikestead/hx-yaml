import massive.munit.TestSuite;

import yaml.type.TBinaryTest;
import yaml.type.TBoolTest;
import yaml.type.TFloatTest;
import yaml.type.TIntTest;
import yaml.type.TMergeTest;
import yaml.type.TNullTest;
import yaml.type.TOmapTest;
import yaml.type.TPairsTest;
import yaml.type.TSetTest;
import yaml.type.TTimestampTest;
import yaml.YamlTest;

/**
 * Auto generated Test Suite for MassiveUnit.
 * Refer to munit command line tool for more information (haxelib run munit)
 */

class TestSuite extends massive.munit.TestSuite
{		

	public function new()
	{
		super();

		add(yaml.type.TBinaryTest);
		add(yaml.type.TBoolTest);
		add(yaml.type.TFloatTest);
		add(yaml.type.TIntTest);
		add(yaml.type.TMergeTest);
		add(yaml.type.TNullTest);
		add(yaml.type.TOmapTest);
		add(yaml.type.TPairsTest);
		add(yaml.type.TSetTest);
		add(yaml.type.TTimestampTest);
		add(yaml.YamlTest);
	}
}
