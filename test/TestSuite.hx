import massive.munit.TestSuite;

import yaml.type.YBinaryTest;
import yaml.type.YBoolTest;
import yaml.type.YFloatTest;
import yaml.type.YIntTest;
import yaml.type.YMergeTest;
import yaml.type.YNullTest;
import yaml.type.YOmapTest;
import yaml.type.YPairsTest;
import yaml.type.YSetTest;
import yaml.type.YTimestampTest;
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

		add(yaml.type.YBinaryTest);
		add(yaml.type.YBoolTest);
		add(yaml.type.YFloatTest);
		add(yaml.type.YIntTest);
		add(yaml.type.YMergeTest);
		add(yaml.type.YNullTest);
		add(yaml.type.YOmapTest);
		add(yaml.type.YPairsTest);
		add(yaml.type.YSetTest);
		add(yaml.type.YTimestampTest);
		add(yaml.YamlTest);
	}
}
