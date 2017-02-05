package massive.munit;

import haxe.PosInfos;

class Assert {
    static public function areEqual(a:Dynamic, b:Dynamic, ?pos:PosInfos) {
        utest.Assert.equals(a, b, pos);
    }

    static public function isFalse(a:Bool, ?pos:PosInfos) {
        utest.Assert.isFalse(a, pos);
    }

    static public function isTrue(a:Bool, ?pos:PosInfos) {
        utest.Assert.isTrue(a, pos);
    }

    static public function isNull(a:Dynamic, ?pos:PosInfos) {
        utest.Assert.isNull(a, pos);
    }

    static public function fail(str:String, ?pos:PosInfos) {
        utest.Assert.fail(str, pos);
    }
}