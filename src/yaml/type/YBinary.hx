package yaml.type;

import haxe.io.Bytes;
import haxe.Utf8;
import yaml.YamlType;

class YBinary extends yaml.StringYamlType<Bytes>
{
	static inline var BASE64_PADDING_CODE = 0x3D;
	static inline var BASE64_PADDING_CHAR = '=';

	static var BASE64_BINTABLE = [
		-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
		-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
		-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 62, -1, -1, -1, 63,
		52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -1, -1, -1,  0, -1, -1,
		-1,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
		15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -1, -1, -1, -1, -1,
		-1, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
		41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -1, -1, -1, -1, -1
	];

	static var BASE64_CHARTABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'.split('');
	
	public function new()
	{
		super('tag:yaml.org,2002:binary', {kind:"string"}, {kind:"binary", instanceOf:Bytes});
	}

	override public function resolve(object:String, ?usingMaps:Bool = true, ?explicit:Bool):Bytes
	{
		var length = Utf8.length(object);
		var idx = 0;
		var result = [];
		var leftbits = 0; // number of bits decoded, but yet to be appended
		var leftdata = 0; // bits decoded, but yet to be appended

		// Convert one by one.
		for (idx in 0...length) 
		{
			var code = Utf8.charCodeAt(object, idx);
			var value = BASE64_BINTABLE[code & 0x7F];

			// Skip LF(NL) || CR
			if (0x0A != code && 0x0D != code) 
			{
				// Fail on illegal characters
				if (-1 == value)
					return cantResolveType();

					// Collect data into leftdata, update bitcount
				leftdata = (leftdata << 6) | value;
				leftbits += 6;
			
					// If we have 8 or more bits, append 8 bits to the result
				if (leftbits >= 8) {
					leftbits -= 8;
			
						// Append if not padding.
					if (BASE64_PADDING_CODE != code) {
						result.push((leftdata >> leftbits) & 0xFF);
					}

					leftdata &= (1 << leftbits) - 1;
				}
			}
		}

		// If there are any bits left, the base64 string was corrupted
		if (leftbits != 0)
			cantResolveType();
		
		var bytes = Bytes.alloc(result.length);
		for (i in 0...result.length)
			bytes.set(i, result[i]);
		
		return bytes;
	}

	override public function represent(object:Bytes, ?style:String):String
	{
		var result = '';
		var index = 0;
		var max = object.length - 2;

		// Convert every three bytes to 4 ASCII characters.
		while (index < max)
		{
			result += BASE64_CHARTABLE[object.get(index + 0) >> 2];
			result += BASE64_CHARTABLE[((object.get(index + 0) & 0x03) << 4) + (object.get(index + 1) >> 4)];
			result += BASE64_CHARTABLE[((object.get(index + 1) & 0x0F) << 2) + (object.get(index + 2) >> 6)];
			result += BASE64_CHARTABLE[object.get(index + 2) & 0x3F];
			index += 3;
		}

		var rest = object.length % 3;

		// Convert the remaining 1 or 2 bytes, padding out to 4 characters.
		if (0 != rest)
		{
			index = object.length - rest;
			result += BASE64_CHARTABLE[object.get(index + 0) >> 2];

			if (2 == rest) 
			{
				result += BASE64_CHARTABLE[((object.get(index + 0) & 0x03) << 4) + (object.get(index + 1) >> 4)];
				result += BASE64_CHARTABLE[(object.get(index + 1) & 0x0F) << 2];
				result += BASE64_PADDING_CHAR;
			} 
			else
			{
				result += BASE64_CHARTABLE[(object.get(index + 0) & 0x03) << 4];
				result += BASE64_PADDING_CODE + BASE64_PADDING_CHAR;
			}
		}
		
		return result;
	}
}
