package yaml;

import yaml.util.StringMap;
import haxe.PosInfos;

typedef POptions = 
{
	?kind:String,
	?skip:Bool
}

typedef ROptions = 
{
	?kind:String,
	?defaultStyle:String,
	?instanceOf:Class<Dynamic>,
	?predicate:Dynamic->Bool,
	?styleAliases:StringMap<String>,
	?skip:Bool
}

typedef AnyYamlType = YamlType<Dynamic, Dynamic>;
typedef StringYamlType<T> = YamlType<T, String>;

class YamlType<T, D>
{
	public var tag:String;
	public var loader:POptions;
	public var dumper:ROptions;
	
    public function new(tag:String, loaderOptions:POptions, dumperOptions:ROptions)
	{
		if (loaderOptions == null && dumperOptions == null)
			throw new YamlException('Incomplete YAML type definition. "loader" or "dumper" setting must be specified.');
		
		this.tag = tag;
		this.loader = loaderOptions;
		this.dumper = dumperOptions;

		if (loaderOptions != null && !loaderOptions.skip)
			validateLoaderOptions();
		if (dumperOptions != null && !dumperOptions.skip)
			validateDumperOptions();
	}

	public function resolve(object:D, ?usingMaps:Bool = true, ?explicit:Bool = false):T
	{
		cantResolveType();
		return null;
	}

	public function represent(object:T, ?style:String):String
	{
		cantRepresentType();
		return null;
	}

	function cantResolveType(?info:PosInfos):Dynamic
	{
		throw new ResolveTypeException("", null, info);
		return null;
	}

	function cantRepresentType(?info:PosInfos):Dynamic
	{
		throw new RepresentTypeException("", null, info);
		return null;
	}

	function validateLoaderOptions()
	{
		if (loader.skip != true && 'string' != loader.kind && 'array' != loader.kind && 'object' != loader.kind)
		{
			throw new YamlException('Unacceptable "kind" setting of a type loader: ' + loader.kind);
		}		
	}
	
	function validateDumperOptions()
	{
		if (dumper.skip != true &&
			'undefined' != dumper.kind &&
			'null'      != dumper.kind &&
			'boolean'   != dumper.kind &&
			'integer'   != dumper.kind &&
			'float'     != dumper.kind &&
			'string'    != dumper.kind &&
			'array'     != dumper.kind &&
			'object'    != dumper.kind &&
			'binary'    != dumper.kind &&
			'function'  != dumper.kind)
		{
			throw new YamlException('Unacceptable "kind" setting of a type dumper: ' + dumper.kind);
		}
	}
}

class ResolveTypeException extends YamlException
{
	public function new(?message:String="", ?cause:Dynamic = null, ?info:PosInfos)
	{
		super(message, cause, info);
	}
}

class RepresentTypeException extends YamlException
{
	public function new(?message:String="", ?cause:Dynamic = null, ?info:PosInfos)
	{
		super(message, cause, info);
	}
}

