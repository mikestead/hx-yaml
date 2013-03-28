package yaml.type;

import massive.munit.Assert;

class TIntTest
{
	static inline var CONST:Int = 685230;

	var type:TInt;

	@Before
    public function before()
	{
		type = new TInt();
	}

	@Test
	public function shouldResolveInt()
	{
		var canonical = "685230";
		var decimal = "+685_230";
		var octal = "02472256";
		var hexadecimalA = "0x_0A_74_AE";
		var hexadecimalB = "0x0A74AE";
		var binaryA = "0b1010_0111_0100_1010_1110";
		var binaryB = "0b10100111010010101110";
		var sexagesimal = "190:20:30";
		
		Assert.areEqual(CONST, type.resolve(canonical));
		Assert.areEqual(CONST, type.resolve(decimal));
		Assert.areEqual(CONST, type.resolve(octal));
		Assert.areEqual(CONST, type.resolve(hexadecimalA));
		Assert.areEqual(CONST, type.resolve(hexadecimalB));
		Assert.areEqual(CONST, type.resolve(binaryA));
		Assert.areEqual(CONST, type.resolve(binaryB));
		Assert.areEqual(CONST, type.resolve(sexagesimal));
	}

	@Test
	public function shouldRepresentInt()
	{
		Assert.areEqual("0b10100111010010101110", type.represent(CONST, "binary"));
		Assert.areEqual("02472256", type.represent(CONST, "octal"));
		Assert.areEqual("685230", type.represent(CONST, "decimal"));
		Assert.areEqual("0xa74ae", type.represent(CONST, "hexadecimal"));
	}
}
