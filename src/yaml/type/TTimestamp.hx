package yaml.type;

import yaml.YamlType;

//class TTimestamp extends StringYamlType<Date>
class TTimestamp extends YamlType<Date, String>
{
	static var YAML_TIMESTAMP_REGEXP = new EReg(
		'^([0-9][0-9][0-9][0-9])'          + // [1] year
		'-([0-9][0-9]?)'                   + // [2] month
		'-([0-9][0-9]?)'                   + // [3] day
		'(?:(?:[Tt]|[ \\t]+)'              + // ...
		'([0-9][0-9]?)'                    + // [4] hour
		':([0-9][0-9])'                    + // [5] minute
		':([0-9][0-9])'                    + // [6] second
		'(?:\\.([0-9]*))?'                 + // [7] fraction
		'(?:[ \\t]*(Z|([-+])([0-9][0-9]?)' + // [8] tz [9] tz_sign [10] tz_hour
		'(?::([0-9][0-9]))?))?)?$', "iu");         // [11] tz_minute
	
    public function new()
	{
		super('tag:yaml.org,2002:timestamp', {kind:"string"}, {kind:"object", instanceOf:Date});
	}

	override public function resolve(object:String, ?explicit:Bool = false):Date
	{
		if (!YAML_TIMESTAMP_REGEXP.match(object))
			cantResolveType();

		// match: [1] year [2] month [3] day
		var year = 0;
		var month = 0;
		var day = 0;
		var hour = 0;
		var minute = 0;
		var second = 0;
		var fraction = 0;
		var delta = 0;

		try 
		{
			year = Std.parseInt(YAML_TIMESTAMP_REGEXP.matched(1));
			month = Std.parseInt(YAML_TIMESTAMP_REGEXP.matched(2)) - 1; // month starts with 0
			day = Std.parseInt(YAML_TIMESTAMP_REGEXP.matched(3));

			hour = Std.parseInt(YAML_TIMESTAMP_REGEXP.matched(4));
			minute = Std.parseInt(YAML_TIMESTAMP_REGEXP.matched(5));
			second = Std.parseInt(YAML_TIMESTAMP_REGEXP.matched(6));

			var f = YAML_TIMESTAMP_REGEXP.matched(7).substring(0, 3);
			while (f.length < 3) { // milli-seconds
				f += '0';
			}
			fraction = Std.parseInt(f);

			if (YAML_TIMESTAMP_REGEXP.matched(9) != null)
			{
				var tz_hour = Std.parseInt(YAML_TIMESTAMP_REGEXP.matched(10));
				var tz_minute = 0;
				try {
					tz_minute = Std.parseInt(YAML_TIMESTAMP_REGEXP.matched(11));
				}
				catch(e:Dynamic) {}
			
				delta = (tz_hour * 60 + tz_minute) * 60000; // delta in mili-seconds
				if ('-' == YAML_TIMESTAMP_REGEXP.matched(9))
					delta = -delta;
			}
		}
		catch(e:Dynamic)  {}

		//TODO(mike): Need to work out how we can do cross platform UTC date creation
//		return new Date(Date.UTC(year, month, day, hour, minute, second, fraction));
		var date = new Date(year, month, day, hour, minute, second);
//		if (delta != 0)
//			date.setTime(data.getTime() - delta);
		return date;
	}

	override public function represent(object:Date, ?style:String):String
	{
		#if (flash || js)
		return mcore.util.Dates.toISOString(object);
		#else
		return object.toString(); // TODO work out how to grab utc time stamp
		#end
		
	}
}
