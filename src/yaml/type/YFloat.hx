package yaml.type;

import yaml.YamlType;
import yaml.util.Floats;

class YFloat extends yaml.StringYamlType<Null<Float>>
{
	static var YAML_FLOAT_PATTERN = new EReg(
		'^(?:[-+]?(?:[0-9][0-9_]*)\\.[0-9_]*(?:[eE][-+][0-9]+)?' +
		'|\\.[0-9_]+(?:[eE][-+][0-9]+)?' +
		'|[-+]?[0-9][0-9_]*(?::[0-5]?[0-9])+\\.[0-9_]*' +
		'|[-+]?\\.(?:inf|Inf|INF)' +
		'|\\.(?:nan|NaN|NAN))$', "iu");

	public function new()
	{
		super('tag:yaml.org,2002:float', {kind:"string"}, {kind:"float", defaultStyle:"lowercase"});
	}

	override public function resolve(object:String, ?usingMaps:Bool = true, ?explicit:Bool):Null<Float>
	{
		if (!YAML_FLOAT_PATTERN.match(object)) 
			cantResolveType();
		
		var value:String = StringTools.replace(object, '_', '').toLowerCase();
		var sign = ('-' == value.charAt(0)) ? -1 : 1;
	
		if (0 <= '+-'.indexOf(value.charAt(0)))
		{
			value = value.substr(1);
		}
	
		if ('.inf' == value) 
		{
			return (1 == sign) ? Math.POSITIVE_INFINITY : Math.NEGATIVE_INFINITY;
		} 
		else if ('.nan' == value)
		{
			return Math.NaN;
		} 
		else if (0 <= value.indexOf(':')) 
		{
			var digits:Array<Float> = [];
			for (v in value.split(':'))
			{
				digits.unshift(Std.parseFloat(v));
			}
	
			var v = 0.0;
			var base = 1;
			
			for (d in digits)
			{
				v += d * base;
				base *= 60;
			}
		
			return sign * v;
	
		}
		else 
		{
			return sign * Std.parseFloat(value);
		}
	}


	override public function represent(object:Null<Float>, ?style:String):String
	{
		if (Math.isNaN(object)) 
		{
			return switch (style) 
			{
				case 'lowercase': '.nan';
				case 'uppercase': '.NAN';
				case 'camelcase': '.NaN';
				default: ".nan";
			}
		} 
		else if (Math.POSITIVE_INFINITY == object) 
		{
			return switch (style) 
			{
				case 'lowercase': '.inf';
				case 'uppercase': '.INF';
				case 'camelcase': '.Inf';
				default: ".inf";
			}
		} 
		else if (Math.NEGATIVE_INFINITY == object) 
		{
			return switch (style)
			{
				case 'lowercase': '-.inf';
				case 'uppercase': '-.INF';
				case 'camelcase': '-.Inf';
				default: "-.inf";
			}
		} 
		else 
		{
			return Floats.toString(object);
		}
	}
}


