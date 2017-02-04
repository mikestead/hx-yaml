package;

import yaml.type.*;
import yaml.YamlTest;
import utest.Runner;
import utest.ui.Report;

class TestPhp {
    static public function main() {
        var runner = new Runner();
        runner.addCase(new YPairsTest());
		runner.addCase(new YIntTest());
		runner.addCase(new YBoolTest());
		runner.addCase(new YSetTest());
		runner.addCase(new YMergeTest());
		runner.addCase(new YFloatTest());
		runner.addCase(new YOmapTest());
		runner.addCase(new YTimestampTest());
		runner.addCase(new YBinaryTest());
		runner.addCase(new YNullTest());
		runner.addCase(new YamlTest());
        Report.create(runner);
        runner.run();
    }
}