package yaml.type;

import yaml.YamlException;
import yaml.util.StringMap;
import yaml.util.Ints;
import yaml.YamlType;

class YInt extends yaml.StringYamlType<Null<Int>>
{
	static var YAML_INTEGER_PATTERN = new EReg(
				'^(?:[-+]?0b[0-1_]+' +
				'|[-+]?0[0-7_]+' +
				'|[-+]?(?:0|[1-9][0-9_]*)' +
				'|[-+]?0x[0-9a-fA-F_]+' +
				'|[-+]?[1-9][0-9_]*(?::[0-5]?[0-9])+)$', "iu");

	public function new()
	{
		super('tag:yaml.org,2002:int', {kind:"string"}, {kind:"integer", defaultStyle:"decimal", styleAliases:createStyleAliases()});
	}
	
	function createStyleAliases()
	{
		var styleAliases = new StringMap<String>();
		styleAliases.set('bin', "binary");
		styleAliases.set('2', "binary");
		styleAliases.set('oct', "octal");
		styleAliases.set('8', "octal");
		styleAliases.set('dec', "decimal");
		styleAliases.set('hex', "hexadecimal");
		styleAliases.set('16', "hexadecimal");
		return styleAliases;
	}
	
	override public function resolve(object:String, ?usingMaps:Bool = true, ?explicit:Bool):Null<Int>
	{
		if (!YAML_INTEGER_PATTERN.match(object))
			cantResolveType();

		var value = StringTools.replace(object, '_', '').toLowerCase();
		var sign = ('-' == value.charAt(0)) ? -1 : 1;
		var digits = [];

		if (0 <= '+-'.indexOf(value.charAt(0)))
		{
			value = value.substr(1);
		}

		if ('0' == value)
		{
			return 0;
		}
		else if (value.indexOf("0b") == 0)
		{
			return sign * Ints.parseInt(value.substr(2), 2);

		}
		else if (value.indexOf("0x") == 0)
		{
			return sign * Ints.parseInt(value, 16);
		} 
		else if (value.indexOf("0") == 0)
		{
			return sign * Ints.parseInt(value, 8);
		} 
		else if (0 <= value.indexOf(':')) // base 60
		{
			for (v in value.split(':'))
			{
				digits.unshift(Ints.parseInt(v, 10));
			}

			var result = 0;
			var base = 1;
	
			for (d in digits) 
			{
				result += (d * base);
				base *= 60;
			}
			
			return sign * result;
		} 
		else 
		{
			return sign * Ints.parseInt(value, 10);
		}
	}

	override public function represent(object:Null<Int>, ?style:String):String
	{
		return switch (style)
		{
			case "binary": '0b' + Ints.toString(object, 2);
			case "octal": '0' + Ints.toString(object, 8);
			case "decimal": Ints.toString(object, 10);
			case "hexadecimal": '0x' + Ints.toString(object, 16);
			default:
				throw new YamlException("Style not supported: " + style);
				null;
		}
	}
}
