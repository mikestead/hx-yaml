package yaml.type;

import massive.munit.Assert;

class YTimestampTest
{
	static var STAMP:Float = 1008385183100;

	var type:YTimestamp;

	public function new() {}

	@Before
    public function setup()
	{
		type = new YTimestamp();
	}

	#if !(js || flash)
	@Ignore("UTC Dates not supported on this target")
	@Test
	public function testShouldResolveTimestamp() Assert.isTrue(true);
	#else
	@Test
	public function testShouldResolveTimestamp()
	{
		var canonical = "2001-12-15T02:59:43.1Z";
		var validIso8601 = "2001-12-14t21:59:43.10-05:00";
		var spaceSeparated = "2001-12-14 21:59:43.10 -5";
		var noTimeZone = "2001-12-15 2:59:43.10";
		var date = "2002-12-14";
		var time:Float = 1039824000000;

		Assert.areEqual(STAMP, type.resolve(canonical).getTime());
		Assert.areEqual(STAMP, type.resolve(validIso8601).getTime());
		Assert.areEqual(STAMP, type.resolve(spaceSeparated).getTime());
		Assert.areEqual(STAMP, type.resolve(noTimeZone).getTime());
		Assert.areEqual(time, type.resolve(date).getTime());
	}
	#end

	#if !(js || flash)
	@Ignore("UTC Dates not supported on this target")
	@Test
	public function testShouldRepresentTimestamp() Assert.isTrue(true);
	#else
	@Test
	public function testShouldRepresentTimestamp()
	{
		Assert.areEqual("2001-12-15T02:59:43.100Z", type.represent(Date.fromTime(STAMP)));
	}
	#end
}
