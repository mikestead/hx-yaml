package yaml;

import haxe.io.Bytes;
import yaml.schema.DefaultSchema;
import mcore.util.Iterables;
import yaml.YamlType;
import yaml.schema.SafeSchema;
import haxe.Utf8;
import mcore.util.Strings;
import mcore.util.Ints;

import yaml.YamlException;

class RenderOptions
{
	public var schema:Schema;
	public var indent:Int;
	public var flowLevel:Int;
	public var styles:StringMap<String>;

	public function new(?indent:Int = 2, ?flowLevel:Int = -1, ?schema:Schema)
	{
		this.indent = indent;
		this.flowLevel = flowLevel;
		this.schema = (schema != null) ? schema : new DefaultSchema();
	}
}

class Renderer
{
	var schema:Schema;
	var indent:Int;
	var flowLevel:Int;
	var styleMap:StringMap<Dynamic>;

	var implicitTypes:Array<AnyYamlType>;
	var explicitTypes:Array<AnyYamlType>;

	var kind:String;
	var tag:String;
	var result:Dynamic;
	
	public function new()
	{}

	public function safeRender(input:Dynamic, options:RenderOptions)
	{
		options.schema = new SafeSchema();
		return render(input, options);
	}
	
	public function render(input:Dynamic, options:RenderOptions)
	{
		schema = options.schema;
		indent    = Std.int(Math.max(1, options.indent));
		flowLevel = options.flowLevel;
		styleMap  = compileStyleMap(schema, options.styles);

		implicitTypes = schema.compiledImplicit;
		explicitTypes = schema.compiledExplicit;

		writeNode(0, input, true, true);
		return result + '\n';
	}
	
	function generateNextLine(level:Int) 
	{
		return '\n' + Strings.repeat(' ', indent * level);
	}

	function testImplicitResolving(object:Dynamic) 
	{
		for (type in implicitTypes)
		{
			try
			{
				type.resolve(object, false);
				return true;
			}
			catch(e:ResolveTypeException) {}
		}

		return false;
	}

	function writeScalar(object:String)
	{
		var isQuoted = false;
		var checkpoint = 0;
		var position = -1;

		result = '';

		if (0 == object.length || 
			CHAR_SPACE == object.charCodeAt(0) || 
			CHAR_SPACE == object.charCodeAt(object.length - 1)) 
		{
			isQuoted = true;
		}

		while (++position < object.length)
		{
			var character = object.charCodeAt(position);
			if (!isQuoted) 
			{
				if (CHAR_TAB == character ||
					CHAR_LINE_FEED == character ||
					CHAR_CARRIAGE_RETURN == character ||
					CHAR_COMMA == character ||
					CHAR_LEFT_SQUARE_BRACKET == character ||
					CHAR_RIGHT_SQUARE_BRACKET == character ||
					CHAR_LEFT_CURLY_BRACKET == character ||
					CHAR_RIGHT_CURLY_BRACKET == character ||
					CHAR_SHARP == character ||
					CHAR_AMPERSAND == character ||
					CHAR_ASTERISK == character ||
					CHAR_EXCLAMATION == character ||
					CHAR_VERTICAL_LINE == character ||
					CHAR_GREATER_THAN == character ||
					CHAR_SINGLE_QUOTE == character ||
					CHAR_DOUBLE_QUOTE == character ||
					CHAR_PERCENT == character ||
					CHAR_COMMERCIAL_AT == character ||
					CHAR_GRAVE_ACCENT == character ||
					CHAR_QUESTION == character ||
					CHAR_COLON == character ||
					CHAR_MINUS == character) 
				{
					isQuoted = true;
				}
			}

			if (ESCAPE_SEQUENCES.exists(character) ||
				!((0x00020 <= character && character <= 0x00007E) ||
				(0x00085 == character)                         ||
				(0x000A0 <= character && character <= 0x00D7FF) ||
				(0x0E000 <= character && character <= 0x00FFFD) ||
				(0x10000 <= character && character <= 0x10FFFF)))
			{
				result += object.substring(checkpoint, position);
				
				if (ESCAPE_SEQUENCES.exists(character))
					result += ESCAPE_SEQUENCES.get(character);
				else
					result += encodeHex(character);
				
				checkpoint = position + 1;
				isQuoted = true;
			}
		}

		if (checkpoint < position)
		{
			result += object.substring(checkpoint, position);
		}

		if (!isQuoted && testImplicitResolving(result))
		{
			isQuoted = true;
		}

		if (isQuoted)
		{
			result = '"' + result + '"';
		}
	}

	function writeFlowSequence(level:Int, object:Array<Dynamic>) 
	{
		var _result = '';
		var _tag = tag;

		for (index in 0...object.length)
		{
			if (0 != index)
				_result += ', ';

			writeNode(level, object[index], false, false);
			_result += result;
		}

		tag = _tag;
		result = '[' + _result + ']';
	}

	function writeBlockSequence(level:Int, object:Array<Dynamic>, compact:Bool) 
	{
		var _result = '';
		var _tag    = tag;
		
		for (index in 0...object.length)
		{
			if (!compact || 0 != index)
			_result += generateNextLine(level);

			writeNode(level + 1, object[index], true, true);
			_result += '- ' + result;
		}

		tag = _tag;
		result = _result;
	}

	function writeFlowMapping(level:Int, object:StringMap<Dynamic>) 
	{
		var _result = '';
		var _tag = tag;
		var index = 0;
		var objectKey;
		
		for (objectKey in object.keys())
		{
			if (0 != index++)
				_result += ', ';

			var objectValue = object.get(objectKey);

			writeNode(level, objectKey, false, false);

			if (result.length > 1024)
				_result += '? ';

			_result += result + ': ';
			writeNode(level, objectValue, false, false);
			_result += result;
		}

		tag = _tag;
		result = '{' + _result + '}';
	}

	function writeBlockMapping(level:Int, object:StringMap<Dynamic>, compact:Bool)
	{
		var _result = '';
		var _tag = tag;
		var index = 0;
		
		for (objectKey in object.keys())
		{
			if (!compact || 0 != index++)
				_result += generateNextLine(level);

			var objectValue = object.get(objectKey);

			writeNode(level + 1, objectKey, true, true);
			var explicitPair = (null != tag && '?' != tag && result.length <= 1024);

			if (explicitPair)
				_result += '? ';

			_result += result;

			if (explicitPair)
				_result += generateNextLine(level);

			writeNode(level + 1, objectValue, true, explicitPair);
			_result += ': ' + result;
		}

		tag = _tag;
		result = _result;
	}

	function detectType(object:Dynamic, explicit:Bool)
	{
		var _result:Dynamic = null;
		var typeList:Array<AnyYamlType> = explicit ? explicitTypes : implicitTypes;
		var style:String;

		kind = kindOf(object);

		for (type in typeList)
		{
			if ((null != type.dumper) &&
				(null == type.dumper.kind || kind == type.dumper.kind) &&
				(null == type.dumper.instanceOf || Std.is(object, type.dumper.instanceOf) &&
				(null == type.dumper.predicate  || type.dumper.predicate(object))))
			{
				tag = explicit ? type.tag : '?';
	
				if (!type.dumper.skip) 
				{
					if (styleMap.exists(type.tag))
						style = styleMap.get(type.tag);
					else
						style = type.dumper.defaultStyle;
			
					var success = true;
					try
					{
						_result = type.represent(object, style);
					}
					catch (e:RepresentTypeException)
					{
						success = false;
					}
					
//					if (Reflect.isFunction(type.dumper.representer))
//					{
//						_result = type.dumper.representer(object, style);
//					} 
//					else if (Std.is(type.dumper.representer, Hash) && type.dumper.representer.exists(style))
//					{
//						_result = type.dumper.representer.get(style)(object, style);
//					} 
//					else 
//					{
//						throw new YamlException('!<' + type.tag + '> tag resolver accepts not "' + style + '" style');
//					}

					if (success) 
					{
						kind = kindOf(_result);
						result = _result;
					} 
					else 
					{
						if (explicit)
							throw new YamlException('cannot represent an object of !<' + type.tag + '> type');
						else
							continue;
					}
				}
				return true;
			}
		}
		return false;
	}

	function writeNode(level:Int, object:Dynamic, block:Bool, compact:Bool) 
	{
		tag = null;
		result = object;

		if (!detectType(object, false))
			detectType(object, true);

		if (block)
			block = (0 > flowLevel || flowLevel > level);

		if ((null != tag && '?' != tag) || (2 != indent && level > 0))
			compact = false;

		if ('object' == kind)
		{
			if (block && !Iterables.isEmpty(result)) 
			{
				writeBlockMapping(level, result, compact);
			}
			else 
			{
				writeFlowMapping(level, result);
			}
		} 
		else if ('array' == kind) 
		{
			if (block && (0 != result.length))
			{
				writeBlockSequence(level, result, compact);
			}
			else
			{
				writeFlowSequence(level, result);
			}
		} 
		else if ('string' == kind) 
		{
			if ('?' != tag) 
			{
				writeScalar(result);
			}
		}
		else if ("binary" == kind)
		{
			trace("binary block? " + block);
		}
		else 
		{
			throw new YamlException('unacceptabe kind of an object to dump (' + kind + ')');
		}

		if (null != tag && '?' != tag) 
		{
			result = '!<' + tag + '> ' + result;
		}
	}

	public function kindOf(object:Dynamic)
	{
		var kind = Type.typeof(object);

		return switch (kind)
		{
			case TNull: "null";
			case TInt: "integer";
			case TFloat: "float";
			case TBool: "boolean";
			case TObject:
				if (Std.is(object, Array)) "array";
//				else if (Std.is(object, Hash)) "map";
				else "object";
			case TFunction: "function";
			case TClass(c):
				if (c == String) "string";
				else if (c == Array) "array";
				else if (c == Bytes) "binary";
				else "object";
			case TEnum(_): "enum";
			case TUnknown: "unknown";
		}
	}

	static function compileStyleMap(schema:Schema, map:StringMap<Dynamic>):StringMap<Dynamic>
	{
		if (null == map)
			return new StringMap();

		var result = new StringMap<Dynamic>();

		for (tag in map.keys())
		{
			var style = Std.string(map.get(tag));

			if (0 == tag.indexOf('!!'))
				tag = 'tag:yaml.org,2002:' + tag.substring(2);

			var type = schema.compiledTypeMap.get(tag);

			if (type != null && type.dumper != null)
			{
				if (type.dumper.styleAliases.exists(style))
				{
					style = type.dumper.styleAliases.get(style);
				}
			}
			result.set(tag, style);
		}

		return result;
	}

	static function encodeHex(charCode:Int)
	{
		var handle:String;
		var length:Int;
		var str = Ints.toString(charCode, 16).toUpperCase();

		if (charCode <= 0xFF)
		{
			handle = 'x';
			length = 2;
		}
		else if (charCode <= 0xFFFF)
		{
			handle = 'u';
			length = 4;
		}
		else if (charCode <= 0xFFFFFFFF)
		{
			handle = 'U';
			length = 8;
		}
		else
		{
			throw new YamlException('code point within a string may not be greater than 0xFFFFFFFF');
		}

		return '\\' + handle + Strings.repeat('0', length - str.length) + str;
	}

	static inline var CHAR_TAB                  = 0x09; /* Tab */
	static inline var CHAR_LINE_FEED            = 0x0A; /* LF */
	static inline var CHAR_CARRIAGE_RETURN      = 0x0D; /* CR */
	static inline var CHAR_SPACE                = 0x20; /* Space */
	static inline var CHAR_EXCLAMATION          = 0x21; /* ! */
	static inline var CHAR_DOUBLE_QUOTE         = 0x22; /* " */
	static inline var CHAR_SHARP                = 0x23; /* # */
	static inline var CHAR_PERCENT              = 0x25; /* % */
	static inline var CHAR_AMPERSAND            = 0x26; /* & */
	static inline var CHAR_SINGLE_QUOTE         = 0x27; /* ' */
	static inline var CHAR_ASTERISK             = 0x2A; /* * */
	static inline var CHAR_COMMA                = 0x2C; /* , */
	static inline var CHAR_MINUS                = 0x2D; /* - */
	static inline var CHAR_COLON                = 0x3A; /* : */
	static inline var CHAR_GREATER_THAN         = 0x3E; /* > */
	static inline var CHAR_QUESTION             = 0x3F; /* ? */
	static inline var CHAR_COMMERCIAL_AT        = 0x40; /* @ */
	static inline var CHAR_LEFT_SQUARE_BRACKET  = 0x5B; /* [ */
	static inline var CHAR_RIGHT_SQUARE_BRACKET = 0x5D; /* ] */
	static inline var CHAR_GRAVE_ACCENT         = 0x60; /* ` */
	static inline var CHAR_LEFT_CURLY_BRACKET   = 0x7B; /* { */
	static inline var CHAR_VERTICAL_LINE        = 0x7C; /* | */
	static inline var CHAR_RIGHT_CURLY_BRACKET  = 0x7D; /* } */
	static var HEX_VALUES = "0123456789ABCDEF";


	static var ESCAPE_SEQUENCES:IntMap<String> =
	{
		var hash = new IntMap<String>();
		hash.set(0x00, '\\0');
		hash.set(0x07, '\\a');
		hash.set(0x08, '\\b');
		hash.set(0x09, '\\t');
		hash.set(0x0A, '\\n');
		hash.set(0x0B, '\\v');
		hash.set(0x0C, '\\f');
		hash.set(0x0D, '\\r');
		hash.set(0x1B, '\\e');
		hash.set(0x22, '\\"');
		hash.set(0x5C, '\\\\');
		hash.set(0x85, '\\N');
		hash.set(0xA0, '\\_');
		hash.set(0x2028, '\\L');
		hash.set(0x2029, '\\P');
		hash;
	};
}
