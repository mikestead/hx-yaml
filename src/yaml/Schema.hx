package yaml;

import yaml.util.StringMap;
import yaml.YamlType;

class Schema
{
	public static var DEFAULT:Schema;
	
	public var compiledImplicit:Array<AnyYamlType>;
	public var compiledExplicit:Array<AnyYamlType>;
	public var compiledTypeMap:StringMap<AnyYamlType>;

	public var implicit:Array<AnyYamlType>;
	public var explicit:Array<AnyYamlType>;
	public var include:Array<Schema>;
	
	public function new(include:Array<Schema>, explicit:Array<AnyYamlType>, ?implicit:Array<AnyYamlType>)
	{
		this.include  = (include == null) ?  [] : include;
		this.implicit = (implicit == null) ? [] : implicit;
		this.explicit = (explicit == null) ? [] : explicit;

		for (type in this.implicit)
		{
			if (null != type.loader && 'string' != type.loader.kind)
			{
				throw new YamlException('There is a non-scalar type in the implicit list of a schema. Implicit resolving of such types is not supported.');
			}
		}

		this.compiledImplicit = compileList(this, 'implicit', []);
		this.compiledExplicit = compileList(this, 'explicit', []);
		this.compiledTypeMap = compileMap([this.compiledImplicit, this.compiledExplicit]);
	}

	public static function create(types:Array<AnyYamlType>, ?schemas:Array<Schema>)
	{
		if (schemas == null)
			schemas = [DEFAULT];
		else if (schemas.length == 0)
			schemas.push(DEFAULT);
	
		return new Schema(schemas, types);
	}
	
	
	public static function compileList(schema:Schema, name:String, result:Array<AnyYamlType>)
	{
		var exclude = [];
		
		for (includedSchema in schema.include)
		{
			result = compileList(includedSchema, name, result);
		}

		var types:Array<AnyYamlType> = switch (name)
		{
			case "implicit": schema.implicit;
			case "explicit": schema.explicit;
			default: throw new YamlException("unknown type list type: " + name);
		}
		
		for (currenYamlType in types) 
		{
			for (previousIndex in 0...result.length)
			{
				var previousType = result[previousIndex];
				if (previousType.tag == currenYamlType.tag)
				{
					exclude.push(previousIndex);
				}
			}
			result.push(currenYamlType);
		}
		
		var filteredResult:Array<AnyYamlType> = [];
		for (i in 0...result.length)
			if (!Lambda.has(exclude, i))
				filteredResult.push(result[i]);
		
		return filteredResult;
	}

	public static function compileMap(list:Array<Array<AnyYamlType>>):StringMap<AnyYamlType>
	{
		var result = new StringMap<AnyYamlType>();

		for (member in list)
			for (type in member)
				result.set(type.tag, type);

		return result;
	}
}
