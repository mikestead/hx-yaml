package yaml;

import Type;
import yaml.util.ObjectMap;
import yaml.util.StringMap;
import yaml.util.IntMap;
import haxe.Utf8;
import haxe.PosInfos;
import yaml.schema.DefaultSchema;
import yaml.schema.SafeSchema;
import yaml.YamlType;
import yaml.util.Strings;
import yaml.util.Ints;

class ParserOptions
{
	public var schema:Schema;
	public var resolve:Bool;
	public var validation:Bool;
	public var strict:Bool;
	public var maps:Bool;

	/**
	@param schema   Defines the schema to use while parsing. Defaults to yaml.schema.DefaultSchema.  
	*/
	public function new(?schema:Schema = null)
	{
		this.schema = (schema == null) ? new DefaultSchema() : schema;
		
		strict = false;
		resolve = true;
		validation = true;
		maps = true;
	}

	/**
	Use yaml.util.ObjectMap as the key => value container. 
	
	Allows for complex key values.
    */
	public function useMaps():ParserOptions
	{
		maps = true;
		return this;
	}

	/**
	Use Dynamic objects as the key => value container.
	
	All keys will become Strings.
    */
	public function useObjects():ParserOptions
	{
		maps = false;
		return this;
	}

	/**
	Defines the schema to use while parsing.
	 
	See yaml.Schema
	*/
	public function setSchema(schema:Schema):ParserOptions
	{
		this.schema = schema;
		return this;
	}

	/**
	Warnings will be thrown as exceptions instead of traced.
	*/
	public function strictMode(?value:Bool = true):ParserOptions
	{
		strict = value;
		return this;
	}

	/**
	Disables validation of yaml document while parsing.
	*/
	public function validate(?value:Bool = true):ParserOptions
	{
		validation = value;
		return this;
	}
}

class Parser
{
	/**
	Utility method to create ParserOptions for configuring a Parser instance. 
    */
	public static function options():ParserOptions
	{
		return new ParserOptions();
	}
	
	var schema:Schema;
	var resolve:Bool;
	var validate:Bool;
	var strict:Bool;
	var usingMaps:Bool;

	var directiveHandlers:StringMap<String->Array<String>->Void>;
	var implicitTypes:Array<AnyYamlType>;
	var typeMap:StringMap<AnyYamlType>;

	var length:Int;
	var position:Int;
	var line:Int;
	var lineStart:Int;
	var lineIndent:Int;
	var character:Null<Int>;

	var version:String;
	var checkLineBreaks:Bool;
	var tagMap:StringMap<String>;
	var anchorMap:StringMap<Dynamic>;
	var tag:String;
	var anchor:String;
	var kind:String;
	var result:Dynamic;
	var input:String;
	var output:Dynamic->Void;

	public function new()
	{}

	public function safeParseAll(input:String, output:Dynamic->Void, options:ParserOptions):Void
	{
		options.schema = new SafeSchema();
		parseAll(input, output, options);
	}

	public function safeParse(input:String, options:ParserOptions)
	{
		options.schema = new SafeSchema();
		return parse(input, options);
	}
	
	public function parse(input:String, options:ParserOptions):Dynamic
	{
		var result:Dynamic = null;
		var received = false;

		var responder = function (data:Dynamic)
		{
			if (!received) 
			{
				result = data;
				received = true;
			} 
			else
			{
				throw new YamlException('expected a single document in the stream, but found more');
			}
		}

		parseAll(input, responder, options);

		return result;
	}
	
	public function parseAll(input:String, output:Dynamic->Void, options:ParserOptions):Void
	{
		#if (neko || cpp)
		this.input = Utf8.encode(input);
		#else
		this.input = input;
		#end
		
		this.output = output;
		
		schema   = options.schema;
		resolve  = options.resolve;
		validate = options.validation;
		strict   = options.strict;
		usingMaps  = options.maps;

		directiveHandlers = new StringMap();
		implicitTypes = schema.compiledImplicit;
		typeMap = schema.compiledTypeMap;

		length = Utf8.length(this.input);//.length;
		position = 0;
		line = 0;
		lineStart = 0;
		lineIndent = 0;
		character = Utf8.charCodeAt(this.input, position);

		directiveHandlers.set('YAML', function(name:String, args:Array<String>)
		{
			#if (cpp || neko)
			for (i in 0...args.length)
				args[i] = Utf8.encode(args[i]);
			#end

			if (null != version)
				throwError('duplication of %YAML directive');

			if (1 != args.length)
				throwError('YAML directive accepts exactly one argument');

			//			match = /^([0-9]+)\.([0-9]+)$/.exec(args[0]);
			var regex = ~/^([0-9]+)\.([0-9]+)$/u;
			if (!regex.match(args[0]))
				throwError('ill-formed argument of the YAML directive');

			var major = Ints.parseInt(regex.matched(1), 10);
			var minor = Ints.parseInt(regex.matched(2), 10);

			if (1 != major)
				throwError('unacceptable YAML version of the document');

			version = args[0];
			checkLineBreaks = (minor < 2);

			if (1 != minor && 2 != minor)
				throwWarning('unsupported YAML version of the document');
		});

		directiveHandlers.set('TAG', function(name:String, args:Array<String>)
		{
			#if (cpp || neko)
			for (i in 0...args.length)
				args[i] = Utf8.encode(args[i]);
			#end
			
			var handle:String;
			var prefix:String;

			if (2 != args.length)
				throwError('TAG directive accepts exactly two arguments');

			handle = args[0];
			prefix = args[1];

			if (!PATTERN_TAG_HANDLE.match(handle))
				throwError('ill-formed tag handle (first argument) of the TAG directive');

			if (tagMap.exists(handle))
				throwError('there is a previously declared suffix for "' + handle + '" tag handle');

			if (!PATTERN_TAG_URI.match(prefix))
				throwError('ill-formed tag prefix (second argument) of the TAG directive');

			tagMap.set(handle, prefix);
		});

		if (validate && PATTERN_NON_PRINTABLE.match(this.input))
		{
			throwError('the stream contains non-printable characters');
		}

		while (CHAR_SPACE == character)
		{
			lineIndent += 1;
			character = Utf8.charCodeAt(input, ++position);
		}

		while (position < length)
		{
			readDocument();
		}
	}
	
	function generateError(message:String, ?info:PosInfos) 
	{
		return new YamlException(message, info);
	}

	function throwError(message:String, ?info:PosInfos) 
	{
		throw generateError(message, info);
	}

	function throwWarning(message:String, ?info:PosInfos) 
	{
		var error = generateError(message, info);

		if (strict) {
			throw error;
		} else {
			trace("Warning : " + error.toString());
		}
	}

	function captureSegment(start:Int, end:Int, checkJson:Bool)
	{
		var _result:String;

		if (start < end) 
		{
			_result = yaml.util.Utf8.substring(input, start, end);

			if (checkJson && validate) 
			{
				for (pos in 0...Utf8.length(_result))//.length)
				{
					var char = Utf8.charCodeAt(_result, pos);
					if (!(0x09 == char || 0x20 <= char && char <= 0x10FFFF))
						throwError('expected valid JSON character');
				}
			}

			result += _result;
		}
	}
	
	// when create dynamic object graph
	function mergeObjectMappings(destination:Dynamic, source:Dynamic)
	{
		if (Type.typeof(source) != ValueType.TObject) {
			throwError('cannot merge mappings; the provided source object is unacceptable');
		}
	
		for (key in Reflect.fields(source))
			if (!Reflect.hasField(destination, key))
				Reflect.setField(destination, key, Reflect.field(source, key));
	}
	
	// when creating map based graph
	function mergeMappings(destination:AnyObjectMap, source:AnyObjectMap)
	{
		if (!Std.is(source, AnyObjectMap)) {
			throwError('cannot merge mappings; the provided source object is unacceptable');
		}
	
		for (key in source.keys())
			if (!destination.exists(key))
				destination.set(key, source.get(key));
	}
	

	function storeObjectMappingPair(_result:Dynamic, keyTag:String, keyNode:Dynamic, valueNode:Dynamic):Dynamic
	{
		if (null == _result)
			_result = {};

		if ('tag:yaml.org,2002:merge' == keyTag)
		{
			if (Std.is(valueNode, Array))
			{
				var list:Array<Dynamic> = cast valueNode;
				for (member in list)
					mergeObjectMappings(_result, member);
			}
			else
			{
				mergeObjectMappings(_result, valueNode);
			}
		}
		else
		{
			Reflect.setField(_result, Std.string(keyNode), valueNode);
		}
		return _result;
	}

	function storeMappingPair(_result:AnyObjectMap, keyTag:String, keyNode:Dynamic, valueNode:Dynamic):AnyObjectMap
	{
		if (null == _result)
		{
			_result = new AnyObjectMap();
		}

		if ('tag:yaml.org,2002:merge' == keyTag)
		{
			if (Std.is(valueNode, Array)) 
			{
				var list:Array<AnyObjectMap> = cast valueNode;
				for (member in list)
					mergeMappings(_result, member);
			}
			else
			{
				mergeMappings(_result, valueNode);
			}
		}
		else
		{
			_result.set(keyNode, valueNode);
		}
		return _result;
	}

	function readLineBreak()
	{
		if (CHAR_LINE_FEED == character)
		{
			position += 1;
		} 
		else if (CHAR_CARRIAGE_RETURN == character)
		{
			if (CHAR_LINE_FEED == Utf8.charCodeAt(input, (position + 1)))
			{
				position += 2;
			} 
			else
			{
				position += 1;
			}
		}
		else
		{
			throwError('a line break is expected');
		}

		line += 1;
		lineStart = position;
		
		if (position < length)
			character = Utf8.charCodeAt(input, position);
		else
			character = null;
	}

	function skipSeparationSpace(allowComments:Bool, checkIndent:Int)
	{
		var lineBreaks = 0;

		while (position < length)
		{
			while (CHAR_SPACE == character || CHAR_TAB == character) 
			{
				character = Utf8.charCodeAt(input, ++position);
			}

			if (allowComments && CHAR_SHARP == character) 
			{
				do { character = Utf8.charCodeAt(input, ++position); }
				while (position < length && CHAR_LINE_FEED != character && CHAR_CARRIAGE_RETURN != character);
			}

			if (CHAR_LINE_FEED == character || CHAR_CARRIAGE_RETURN == character)
			{
				readLineBreak();
				lineBreaks += 1;
				lineIndent = 0;

				while (CHAR_SPACE == character)
				{
					lineIndent += 1;
					character = Utf8.charCodeAt(input, ++position);
				}

				if (lineIndent < checkIndent)
				{
					throwWarning('deficient indentation');
				}
			} 
			else 
			{
				break;
			}
		}

		return lineBreaks;
	}

	function testDocumentSeparator()
	{
		if (position == lineStart && 
						(CHAR_MINUS == character || CHAR_DOT == character) &&
						Utf8.charCodeAt(input, (position + 1)) == character &&
						Utf8.charCodeAt(input, (position + 2)) == character) 
		{

			var pos = position + 3;
			var char = Utf8.charCodeAt(input, pos);

			if (pos >= length || CHAR_SPACE == char || CHAR_TAB == char || 
				CHAR_LINE_FEED == char || CHAR_CARRIAGE_RETURN == char) 
			{
				return true;
			}
		}

		return false;
	}

	function writeFoldedLines(count:Int) 
	{
		if (1 == count)
		{
			result += ' ';
		}
		else if (count > 1)
		{
			#if (cpp || neko)
			result += Utf8.encode(Strings.repeat('\n', count - 1));
			#else
			result += Strings.repeat('\n', count - 1);
			#end
		}
	}

	function readPlainScalar(nodeIndent:Int, withinFlowCollection:Bool)
	{
		var preceding:Int;
		var following:Int;
		var captureStart:Int;
		var captureEnd:Int;
		var hasPendingContent;
		
		var _line:Int = 0;
		var _kind = kind;
		var _result = result;

		if (CHAR_SPACE == character ||
			CHAR_TAB == character ||
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
			CHAR_GRAVE_ACCENT == character)
		{
			return false;
		}

		if (CHAR_QUESTION == character || CHAR_MINUS == character) 
		{
			following = Utf8.charCodeAt(input, position + 1);

			if (CHAR_SPACE == following ||
				CHAR_TAB == following ||
				CHAR_LINE_FEED == following ||
				CHAR_CARRIAGE_RETURN == following ||
				withinFlowCollection &&
				(CHAR_COMMA == following ||
				CHAR_LEFT_SQUARE_BRACKET  == following ||
				CHAR_RIGHT_SQUARE_BRACKET == following ||
				CHAR_LEFT_CURLY_BRACKET   == following ||
				CHAR_RIGHT_CURLY_BRACKET  == following)) 
			{
				return false;
			}
		}

		kind = KIND_STRING;
		result = '';
		captureStart = captureEnd = position;
		hasPendingContent = false;

		while (position < length)
		{
			if (CHAR_COLON == character) 
			{
				following = Utf8.charCodeAt(input, position + 1);

				if (CHAR_SPACE == following ||
					CHAR_TAB == following ||
					CHAR_LINE_FEED == following ||
					CHAR_CARRIAGE_RETURN == following ||
					withinFlowCollection &&
					(CHAR_COMMA == following ||
					CHAR_LEFT_SQUARE_BRACKET  == following ||
					CHAR_RIGHT_SQUARE_BRACKET == following ||
					CHAR_LEFT_CURLY_BRACKET   == following ||
					CHAR_RIGHT_CURLY_BRACKET  == following)) 
				{
					break;
				}

			}
			else if (CHAR_SHARP == character)
			{
				preceding = Utf8.charCodeAt(input, position - 1);

				if (CHAR_SPACE == preceding ||
					CHAR_TAB == preceding ||
					CHAR_LINE_FEED == preceding ||
					CHAR_CARRIAGE_RETURN == preceding)
				{
					break;
				}

			} 
			else if ((position == lineStart && testDocumentSeparator()) ||
				withinFlowCollection &&
				(CHAR_COMMA == character ||
				CHAR_LEFT_SQUARE_BRACKET == character ||
				CHAR_RIGHT_SQUARE_BRACKET == character ||
				CHAR_LEFT_CURLY_BRACKET == character ||
				CHAR_RIGHT_CURLY_BRACKET == character))
			{
					break;

			}
			else if (CHAR_LINE_FEED == character || CHAR_CARRIAGE_RETURN == character)
			{
				_line = line;
				var _lineStart = lineStart;
				var _lineIndent = lineIndent;
				
				skipSeparationSpace(false, -1);

				if (lineIndent >= nodeIndent) 
				{
					hasPendingContent = true;
					continue;
				} 
				else 
				{
					position = captureEnd;
					line = _line;
					lineStart = _lineStart;
					lineIndent = _lineIndent;
					character = Utf8.charCodeAt(input, position);
					break;
				}
			}

			if (hasPendingContent)
			{
				captureSegment(captureStart, captureEnd, false);
				writeFoldedLines(line - _line);
				captureStart = captureEnd = position;
				hasPendingContent = false;
			}

			if (CHAR_SPACE != character && CHAR_TAB != character) 
			{
				captureEnd = position + 1;
			}

			if (++position >= length)
				break;
			
			character = Utf8.charCodeAt(input, position);
		}

		captureSegment(captureStart, captureEnd, false);

		if (result != null) 
		{
			#if sys
			result = Utf8.decode(result); // convert back into native encoding
			#end
			return true;
		} 
		else
		{
			kind = _kind;
			result = _result;
			return false;
		}
	}

	function readSingleQuotedScalar(nodeIndent:Int)
	{
		var captureStart:Int;
		var captureEnd:Int;

		if (CHAR_SINGLE_QUOTE != character)
		{
			return false;
		}

		kind = KIND_STRING;
		result = '';
		character = Utf8.charCodeAt(input, ++position);
		captureStart = captureEnd = position;

		while (position < length) 
		{
			if (CHAR_SINGLE_QUOTE == character)
			{
				captureSegment(captureStart, position, true);
				character = Utf8.charCodeAt(input, ++position);

				if (CHAR_SINGLE_QUOTE == character) 
				{
					captureStart = captureEnd = position;
					character = Utf8.charCodeAt(input, ++position);
				} 
				else 
				{
					#if sys
					result = Utf8.decode(result);
					#end
					return true;
				}

			}
			else if (CHAR_LINE_FEED == character || CHAR_CARRIAGE_RETURN == character) 
			{
				captureSegment(captureStart, captureEnd, true);
				writeFoldedLines(skipSeparationSpace(false, nodeIndent));
				captureStart = captureEnd = position;
				character = Utf8.charCodeAt(input, position);
			} 
			else if (position == lineStart && testDocumentSeparator()) 
			{
				throwError('unexpected end of the document within a single quoted scalar');
			} 
			else 
			{
				character = Utf8.charCodeAt(input, ++position);
				captureEnd = position;
			}
		}

		throwError('unexpected end of the stream within a single quoted scalar');
		return false;
	}

	function readDoubleQuotedScalar(nodeIndent:Int) 
	{
		var captureStart:Int;
		var captureEnd:Int;

		if (CHAR_DOUBLE_QUOTE != character)
			return false;

		kind = KIND_STRING;
		result = '';
		character = Utf8.charCodeAt(input, ++position);
		captureStart = captureEnd = position;

		while (position < length)
		{
			if (CHAR_DOUBLE_QUOTE == character)
			{
				captureSegment(captureStart, position, true);
				character = Utf8.charCodeAt(input, ++position);

				#if sys
				result = Utf8.decode(result);
				#end
				return true;

			}
			else if (CHAR_BACKSLASH == character)
			{
				captureSegment(captureStart, position, true);
				character = Utf8.charCodeAt(input, ++position);

				if (CHAR_LINE_FEED == character || CHAR_CARRIAGE_RETURN == character) 
				{
					skipSeparationSpace(false, nodeIndent);
				}
				else if (SIMPLE_ESCAPE_SEQUENCES.exists(character)) 
				{
					result += SIMPLE_ESCAPE_SEQUENCES.get(character);
					character = Utf8.charCodeAt(input, ++position);
				}
				else if (HEXADECIMAL_ESCAPE_SEQUENCES.exists(character))
				{
					var hexLength = HEXADECIMAL_ESCAPE_SEQUENCES.get(character);
					var hexResult = 0;

					for (hexIndex in 1...hexLength)
					{
						var hexOffset = (hexLength - hexIndex) * 4;
						character = Utf8.charCodeAt(input, ++position);

						if (CHAR_DIGIT_ZERO <= character && character <= CHAR_DIGIT_NINE)
						{
							hexResult |= (character - CHAR_DIGIT_ZERO) << hexOffset;
						}
						else if (CHAR_CAPITAL_A <= character && character <= CHAR_CAPITAL_F)
						{
							hexResult |= (character - CHAR_CAPITAL_A + 10) << hexOffset;
						}
						else if (CHAR_SMALL_A <= character && character <= CHAR_SMALL_F)
						{
							hexResult |= (character - CHAR_SMALL_A + 10) << hexOffset;
						}
						else {
							throwError('expected hexadecimal character');
						}
					}

					result += String.fromCharCode(hexResult);
					character = Utf8.charCodeAt(input, ++position);

				}
				else 
				{
					throwError('unknown escape sequence');
				}

				captureStart = captureEnd = position;

			} 
			else if (CHAR_LINE_FEED == character || CHAR_CARRIAGE_RETURN == character)
			{
				captureSegment(captureStart, captureEnd, true);
				writeFoldedLines(skipSeparationSpace(false, nodeIndent));
				captureStart = captureEnd = position;
				character = Utf8.charCodeAt(input, position);
			}
			else if (position == lineStart && testDocumentSeparator())
			{
				throwError('unexpected end of the document within a double quoted scalar');
			}
			else
			{
				character = Utf8.charCodeAt(input, ++position);
				captureEnd = position;
			}
		}

		throwError('unexpected end of the stream within a double quoted scalar');
		return false;
	}

	function composeNode(parentIndent:Int, nodeContext:Int, allowToSeek:Bool, allowCompact:Bool)
	{
		var allowBlockStyles:Bool;
		var allowBlockScalars:Bool;
		var allowBlockCollections:Bool;
		var atNewLine = false;
		var isIndented = true;
		var hasContent = false;

		tag    = null;
		anchor = null;
		kind   = null;
		result = null;

		allowBlockCollections = (CONTEXT_BLOCK_OUT == nodeContext || CONTEXT_BLOCK_IN  == nodeContext);
		allowBlockStyles = allowBlockScalars = allowBlockCollections;

		if (allowToSeek)
		{
			if (skipSeparationSpace(true, -1) != 0)
			{
				atNewLine = true;

				if (lineIndent == parentIndent)
				{
					isIndented = false;
				}
				else if (lineIndent > parentIndent)
				{
					isIndented = true;
				}
				else
				{
					return false;
				}
			}
		}

		if (isIndented)
		{
			while (readTagProperty() || readAnchorProperty())
			{
				if (skipSeparationSpace(true, -1) != 0)
				{
					atNewLine = true;

					if (lineIndent > parentIndent)
					{
						isIndented = true;
						allowBlockCollections = allowBlockStyles;
					}
					else if (lineIndent == parentIndent)
					{
						isIndented = false;
						allowBlockCollections = allowBlockStyles;

					}
					else
					{
						return true;
					}
				}
				else
				{
					allowBlockCollections = false;
				}
			}
		}

		if (allowBlockCollections)
			allowBlockCollections = atNewLine || allowCompact;

		if (isIndented || CONTEXT_BLOCK_OUT == nodeContext)
		{
			var flowIndent:Int;
			var blockIndent:Int;
			if (CONTEXT_FLOW_IN == nodeContext || CONTEXT_FLOW_OUT == nodeContext)
			{
				flowIndent = parentIndent;
			}
			else
			{
				flowIndent = parentIndent + 1;
			}

			blockIndent = position - lineStart;

			if (isIndented)
			{
				if (allowBlockCollections &&
					(readBlockSequence(blockIndent) ||
					readBlockMapping(blockIndent)) ||
					readFlowCollection(flowIndent))
				{
					hasContent = true;
				}
				else
				{
					if ((allowBlockScalars && readBlockScalar(flowIndent)) ||
					readSingleQuotedScalar(flowIndent) ||
					readDoubleQuotedScalar(flowIndent))
					{
						hasContent = true;
					}
					else if (readAlias())
					{
						hasContent = true;

						if (null != tag || null != anchor)
						{
							throwError('alias node should not have any properties');
						}

					}
					else if (readPlainScalar(flowIndent, CONTEXT_FLOW_IN == nodeContext))
					{
						hasContent = true;

						if (null == tag)
							tag = '?';
					}
					

					if (null != anchor)
					{
						anchorMap.set(anchor, result);
					}
				}
			}
			else
			{
				hasContent = allowBlockCollections && readBlockSequence(blockIndent);
			}
		}
		
		if (null != tag && '!' != tag)
		{
			var _result:Dynamic = null;

			if ('?' == tag)
			{
				if (resolve)
				{
					for (typeIndex in 0...implicitTypes.length)
					{
						var type = implicitTypes[typeIndex];
						// Implicit resolving is not allowed for non-scalar types, and '?'
						// non-specific tag is only assigned to plain scalars. So, it isn't
						// needed to check for 'kind' conformity.
						var resolvedType = false;
						
						try
						{
							_result = type.resolve(result, usingMaps, false);
							#if sys
							if (Std.is(_result, String))
								_result = Utf8.decode(_result);
							#end
							tag = type.tag;
							result = _result;
							resolvedType = true;
						}
						catch (e:ResolveTypeException) {}
						
						if (resolvedType) break;
					}
				}
			}
			else if (typeMap.exists(tag))
			{
				var t = typeMap.get(tag);

				if (null != result && t.loader.kind != kind)
				{
					throwError('unacceptable node kind for !<' + tag + '> tag; it should be "' + t.loader.kind + '", not "' + kind + '"');
				}

				if (!t.loader.skip)
				{
					
					try
					{
						_result = t.resolve(result, usingMaps, true);
						#if sys
						if (Std.is(_result, String))
							_result = Utf8.decode(_result);
						#end
						
						result = _result;
					}
					catch(e:ResolveTypeException)
					{
						throwError('cannot resolve a node with !<' + tag + '> explicit tag');
					}
				}
			}
			else
			{
				throwWarning('unknown tag !<' + tag + '>');
			}
		}
		
		return (null != tag || null != anchor || hasContent);
	}

	function readFlowCollection(nodeIndent:Int)
	{
		var readNext = true;
		var _tag = tag;
		var _result:Dynamic;
		var terminator:Int;
		var isPair:Bool;
		var isExplicitPair:Bool;
		var isMapping:Bool;
		var keyNode:Dynamic;
		var keyTag:String;
		var valueNode:Dynamic;

		switch (character)
		{
			case CHAR_LEFT_SQUARE_BRACKET:
				terminator = CHAR_RIGHT_SQUARE_BRACKET;
				isMapping = false;
				_result = [];

			case CHAR_LEFT_CURLY_BRACKET:
				terminator = CHAR_RIGHT_CURLY_BRACKET;
				isMapping = true;
				_result = usingMaps ? new ObjectMap<{}, Dynamic>() :  {};

			default:
				return false;
		}

		if (null != anchor)
			anchorMap.set(anchor, _result);

		character = Utf8.charCodeAt(input, ++position);

		while (position < length)
		{
			skipSeparationSpace(true, nodeIndent);

			if (character == terminator)
			{
				character = Utf8.charCodeAt(input, ++position);
				tag = _tag;
				kind = isMapping ? KIND_OBJECT : KIND_ARRAY;
				result = _result;
				return true;
			} 
			else if (!readNext) 
			{
				throwError('missed comma between flow collection entries');
			}

			keyTag = keyNode = valueNode = null;
			isPair = isExplicitPair = false;

			if (CHAR_QUESTION == character)
			{
				var following = Utf8.charCodeAt(input, position + 1);

				if (CHAR_SPACE == following ||
					CHAR_TAB == following ||
					CHAR_LINE_FEED == following ||
					CHAR_CARRIAGE_RETURN == following) 
				{
					isPair = isExplicitPair = true;
					position += 1;
					character = following;
					skipSeparationSpace(true, nodeIndent);
				}
			}

			var _line = line;
			composeNode(nodeIndent, CONTEXT_FLOW_IN, false, true);
			keyTag = tag;
			keyNode = result;

			if ((isExplicitPair || line == _line) && CHAR_COLON == character)
			{
				isPair = true;
				character = Utf8.charCodeAt(input, ++position);
				skipSeparationSpace(true, nodeIndent);
				composeNode(nodeIndent, CONTEXT_FLOW_IN, false, true);
				valueNode = result;
			}
			
			if (isMapping)
			{
				if (usingMaps)
					storeMappingPair(_result, keyTag, keyNode, valueNode);
				else
					storeObjectMappingPair(_result, keyTag, keyNode, valueNode);
			}
			else if (isPair) 
			{
				if (usingMaps)
					_result.push(storeMappingPair(null, keyTag, keyNode, valueNode));
				else
					_result.push(storeObjectMappingPair(null, keyTag, keyNode, valueNode));
			}
			else 
			{
				_result.push(keyNode);
			}

			skipSeparationSpace(true, nodeIndent);

			if (CHAR_COMMA == character)
			{
				readNext = true;
				character = Utf8.charCodeAt(input, ++position);
			} 
			else
			{
				readNext = false;
			}
		}

		throwError('unexpected end of the stream within a flow collection');
		return false;
	}

	function readBlockScalar(nodeIndent:Int) 
	{
		var captureStart:Int;
		var folding:Bool;
		var chomping = CHOMPING_CLIP;
		var detectedIndent = false;
		var textIndent = nodeIndent;
		var emptyLines = -1;

		switch (character) 
		{
			case CHAR_VERTICAL_LINE:
				folding = false;

			case CHAR_GREATER_THAN:
				folding = true;

			default:
				return false;
		}

		kind = KIND_STRING;
		result = '';

		while (position < length) 
		{
			character = Utf8.charCodeAt(input, ++position);

			if (CHAR_PLUS == character || CHAR_MINUS == character) 
			{
				if (CHOMPING_CLIP == chomping) 
				{
					chomping = (CHAR_PLUS == character) ? CHOMPING_KEEP : CHOMPING_STRIP;
				}
				else 
				{
					throwError('repeat of a chomping mode identifier');
				}

			}
			else if (CHAR_DIGIT_ZERO <= character && character <= CHAR_DIGIT_NINE)
			{
				if (CHAR_DIGIT_ZERO == character)
				{
					throwError('bad explicit indentation width of a block scalar; it cannot be less than one');
				}
				else if (!detectedIndent)
				{
					textIndent = nodeIndent + (character - CHAR_DIGIT_ONE);
					detectedIndent = true;
				}
				else
				{
					throwError('repeat of an indentation width identifier');
				}
			}
			else 
			{
				break;
			}
		}

		if (CHAR_SPACE == character || CHAR_TAB == character)
		{
			do { character = Utf8.charCodeAt(input, ++position); }
			while (CHAR_SPACE == character || CHAR_TAB == character);

			if (CHAR_SHARP == character) 
			{
				do { character = Utf8.charCodeAt(input, ++position); }
				while (position < length && CHAR_LINE_FEED != character && CHAR_CARRIAGE_RETURN != character);
			}
		}

		while (position < length) 
		{
			readLineBreak();
			lineIndent = 0;

			while ((!detectedIndent || lineIndent < textIndent) && (CHAR_SPACE == character)) 
			{
				lineIndent += 1;
				character = Utf8.charCodeAt(input, ++position);
			}

			if (!detectedIndent && lineIndent > textIndent)
			{
				textIndent = lineIndent;
			}

			if (CHAR_LINE_FEED == character || CHAR_CARRIAGE_RETURN == character) 
			{
				emptyLines += 1;
				continue;
			}

			// End of the scalar. Perform the chomping.
			if (lineIndent < textIndent) 
			{
				if (CHOMPING_KEEP == chomping) 
				{
					#if sys
					result += Utf8.encode(Strings.repeat('\n', emptyLines + 1));
					#else
					result += Strings.repeat('\n', emptyLines + 1);
					#end
				} 
				else if (CHOMPING_CLIP == chomping) 
				{
					result += '\n';
				}
				break;
			}

			detectedIndent = true;

			if (folding) 
			{
				if (CHAR_SPACE == character || CHAR_TAB == character) 
				{
					#if sys
					result += Utf8.encode(Strings.repeat('\n', emptyLines + 1));
					#else
					result += Strings.repeat('\n', emptyLines + 1);
					#end
					emptyLines = 1;
				}
				else if (0 == emptyLines) 
				{
					#if sys
					result += Utf8.encode(' ');
					#else
					result += ' ';
					#end
					
					emptyLines = 0;
				} 
				else 
				{
					#if sys
					result += Utf8.encode(Strings.repeat('\n', emptyLines));
					#else
					result += Strings.repeat('\n', emptyLines);
					#end
					emptyLines = 0;
				}
			} 
			else 
			{
				#if sys
				result += Utf8.encode(Strings.repeat('\n', emptyLines + 1));
				#else
				result += Strings.repeat('\n', emptyLines + 1);
				#end
				emptyLines = 0;
			}

			captureStart = position;

			do { character = Utf8.charCodeAt(input, ++position); }
			while (position < length && CHAR_LINE_FEED != character && CHAR_CARRIAGE_RETURN != character);

			captureSegment(captureStart, position, false);
		}
		
		#if sys
		result = Utf8.decode(result);
		#end

		return true;
	}

	function readBlockSequence(nodeIndent:Int) 
	{
		var _line:Int;
		var _tag = tag;
		var _result:Array<Dynamic> = [];
		var following:Int;
		var detected  = false;

		if (null != anchor)
			anchorMap.set(anchor, _result);

		while (position < length) 
		{
			if (CHAR_MINUS != character)
				break;

			following = Utf8.charCodeAt(input, position + 1);

			if (CHAR_SPACE != following &&
				CHAR_TAB != following &&
				CHAR_LINE_FEED != following &&
				CHAR_CARRIAGE_RETURN != following) 
			{
				break;
			}

			detected = true;
			position += 1;
			character = following;

			if (skipSeparationSpace(true, -1) != 0) 
			{
				if (lineIndent <= nodeIndent) 
				{
					_result.push(null);
					continue;
				}
			}

			_line = line;
			composeNode(nodeIndent, CONTEXT_BLOCK_IN, false, true);
			_result.push(result);
			skipSeparationSpace(true, -1);

			if ((line == _line || lineIndent > nodeIndent) && position < length) 
			{
				throwError('bad indentation of a sequence entry');
			}
			else if (lineIndent < nodeIndent) 
			{
				break;
			}
		}

		if (detected) 
		{
			tag = _tag;
			kind = KIND_ARRAY;
			result = _result;
			return true;
		} 
		else 
		{
			return false;
		}
	}

	function readBlockMapping(nodeIndent:Int)
	{
		var following:Int;
		var allowCompact = false;
		var _line:Int;
		var _tag = tag;
		var _result:Dynamic = usingMaps ? new ObjectMap<{}, Dynamic>() : {};
		
		var keyTag:Dynamic = null;
		var keyNode:Dynamic = null;
		var valueNode:Dynamic = null;
		var atExplicitKey = false;
		var detected = false;

		if (null != anchor)
			anchorMap.set(anchor, _result);

		while (position < length)
		{
			following = Utf8.charCodeAt(input, position + 1);
			_line = line; // Save the current line.

			if ((CHAR_QUESTION == character ||
				CHAR_COLON == character) &&
				(CHAR_SPACE == following ||
				CHAR_TAB == following ||
				CHAR_LINE_FEED == following ||
				CHAR_CARRIAGE_RETURN == following)) 
			{
				if (CHAR_QUESTION == character) 
				{
					if (atExplicitKey) 
					{
						if (usingMaps)
							storeMappingPair(_result, keyTag, keyNode, null);
						else
							storeObjectMappingPair(_result, keyTag, keyNode, null);
						keyTag = keyNode = valueNode = null;
					}

					detected = true;
					atExplicitKey = true;
					allowCompact = true;

				} 
				else if (atExplicitKey) 
				{
					// i.e. CHAR_COLON == character after the explicit key.
					atExplicitKey = false;
					allowCompact = true;

				} 
				else 
				{
					throwError('incomplete explicit mapping pair; a key node is missed');
				}

				position += 1;
				character = following;

			}
			else if (composeNode(nodeIndent, CONTEXT_FLOW_OUT, false, true)) 
			{
				if (line == _line)
				{
					// TODO: Remove this cycle when the flow readers will consume
					// trailing whitespaces like the block readers.
					while (CHAR_SPACE == character || CHAR_TAB == character) 
					{
						character = Utf8.charCodeAt(input, ++position);
					}

					if (CHAR_COLON == character) 
					{
						character = Utf8.charCodeAt(input, ++position);

						if (CHAR_SPACE != character &&
							CHAR_TAB != character &&
							CHAR_LINE_FEED != character &&
							CHAR_CARRIAGE_RETURN != character) 
						{
							throwError('a whitespace character is expected after the key-value separator within a block mapping');
						}

						if (atExplicitKey) 
						{
							if (usingMaps)
								storeMappingPair(_result, keyTag, keyNode, null);
							else
								storeObjectMappingPair(_result, keyTag, keyNode, null);
							
							keyTag = keyNode = valueNode = null;
						}

						detected = true;
						atExplicitKey = false;
						allowCompact = false;
						keyTag = tag;
						keyNode = result;

					} 
					else if (detected) 
					{
						throwError('can not read an implicit mapping pair; a colon is missed');

					} 
					else 
					{
						tag = _tag;
						return true; // Keep the result of `composeNode`.
					}

				}
				else if (detected) 
				{
					throwError('can not read a block mapping entry; a multiline key may not be an implicit key');
				}
				else 
				{
					tag = _tag;
					return true; // Keep the result of `composeNode`.
				}
			} 
			else 
			{
				break;
			}

			if (line == _line || lineIndent > nodeIndent) 
			{
				if (composeNode(nodeIndent, CONTEXT_BLOCK_OUT, true, allowCompact)) 
				{
					if (atExplicitKey)
						keyNode = result;
					else
						valueNode = result;
				}

				if (!atExplicitKey) 
				{
					if (usingMaps)
						storeMappingPair(_result, keyTag, keyNode, valueNode);
					else
						storeObjectMappingPair(_result, keyTag, keyNode, valueNode);
					keyTag = keyNode = valueNode = null;
				}

				// TODO: It is needed only for flow node readers. It should be removed
				// when the flow readers will consume trailing whitespaces as well as
				// the block readers.
				skipSeparationSpace(true, -1);
			}

			if (lineIndent > nodeIndent && position < length) 
			{
				throwError('bad indentation of a mapping entry');
			} 
			else if (lineIndent < nodeIndent) 
			{
				break;
			}
		}

		if (atExplicitKey) 
		{
			if (usingMaps)
				storeMappingPair(_result, keyTag, keyNode, null);
			else
				storeObjectMappingPair(_result, keyTag, keyNode, null);
		}

		if (detected) 
		{
			tag = _tag;
			kind = KIND_OBJECT;
			result = _result;
		}

		return detected;
	}

	function readTagProperty() 
	{
		var _position:Int;
		var isVerbatim = false;
		var isNamed = false;
		var tagHandle:String = null;
		var tagName:String = null;

		if (CHAR_EXCLAMATION != character)
			return false;

		if (null != tag)
			throwError('duplication of a tag property');

		character = Utf8.charCodeAt(input, ++position);

		if (CHAR_LESS_THAN == character)
		{
			isVerbatim = true;
			character = Utf8.charCodeAt(input, ++position);

		}
		else if (CHAR_EXCLAMATION == character)
		{
			isNamed = true;
			tagHandle = '!!';
			character = Utf8.charCodeAt(input, ++position);
		} 
		else
		{
			tagHandle = '!';
		}

		_position = position;

		if (isVerbatim)
		{
			do { character = Utf8.charCodeAt(input, ++position); }
			while (position < length && CHAR_GREATER_THAN != character);

			if (position < length) 
			{
				tagName = yaml.util.Utf8.substring(input, _position, position);
				character = Utf8.charCodeAt(input, ++position);
			}
			else
			{
				throwError('unexpected end of the stream within a verbatim tag');
			}
		}
		else
		{
			while (position < length &&
					CHAR_SPACE != character &&
					CHAR_TAB != character &&
					CHAR_LINE_FEED != character &&
					CHAR_CARRIAGE_RETURN != character)
			{
				if (CHAR_EXCLAMATION == character)
				{
					if (!isNamed)
					{
						tagHandle = yaml.util.Utf8.substring(input, _position - 1, position + 1);

						if (validate && !PATTERN_TAG_HANDLE.match(tagHandle))
						{
							throwError('named tag handle cannot contain such characters');
						}

						isNamed = true;
						_position = position + 1;
					}
					else
					{
						throwError('tag suffix cannot contain exclamation marks');
					}
				}

				character = Utf8.charCodeAt(input, ++position);
			}

			tagName = yaml.util.Utf8.substring(input, _position, position);

			if (validate && PATTERN_FLOW_INDICATORS.match(tagName))
			{
				throwError('tag suffix cannot contain flow indicator characters');
			}
		}

		if (validate && tagName != null && tagName != "" && !PATTERN_TAG_URI.match(tagName))
		{
			throwError('tag name cannot contain such characters: ' + tagName);
		}

		if (isVerbatim)
		{
			tag = tagName;
		}
		else if (tagMap.exists(tagHandle))
		{
			tag = tagMap.get(tagHandle) + tagName;
		}
		else if ('!' == tagHandle)
		{
			tag = '!' + tagName;
		}
		else if ('!!' == tagHandle)
		{
			tag = 'tag:yaml.org,2002:' + tagName;
		}
		else 
		{
			throwError('undeclared tag handle "' + tagHandle + '"');
		}

		return true;
	}

	function readAnchorProperty()
	{
		var _position:Int;

		if (CHAR_AMPERSAND != character)
			return false;

		if (null != anchor)
			throwError('duplication of an anchor property');

		character = Utf8.charCodeAt(input, ++position);
		_position = position;

		while (position < length &&
				CHAR_SPACE != character &&
				CHAR_TAB != character &&
				CHAR_LINE_FEED != character &&
				CHAR_CARRIAGE_RETURN != character &&
				CHAR_COMMA != character &&
				CHAR_LEFT_SQUARE_BRACKET != character &&
				CHAR_RIGHT_SQUARE_BRACKET != character &&
				CHAR_LEFT_CURLY_BRACKET != character &&
				CHAR_RIGHT_CURLY_BRACKET != character) 
		{
			character = Utf8.charCodeAt(input, ++position);
		}

		if (position == _position)
			throwError('name of an anchor node must contain at least one character');

		anchor = yaml.util.Utf8.substring(input, _position, position);
		return true;
	}

	function readAlias() 
	{
		var _position:Int;
		var alias:String;

		if (CHAR_ASTERISK != character)
			return false;

		character = Utf8.charCodeAt(input, ++position);
		_position = position;

		while (position < length &&
				CHAR_SPACE != character &&
				CHAR_TAB != character &&
				CHAR_LINE_FEED != character &&
				CHAR_CARRIAGE_RETURN != character &&
				CHAR_COMMA != character &&
				CHAR_LEFT_SQUARE_BRACKET != character &&
				CHAR_RIGHT_SQUARE_BRACKET != character &&
				CHAR_LEFT_CURLY_BRACKET != character &&
				CHAR_RIGHT_CURLY_BRACKET != character)
		{
			character = Utf8.charCodeAt(input, ++position);
		}

		if (position == _position)
			throwError('name of an alias node must contain at least one character');

		alias = yaml.util.Utf8.substring(input, _position, position);
		
		if (!anchorMap.exists(alias))
			throwError('unidentified alias "' + alias + '"');

		result = anchorMap.get(alias);
		
		skipSeparationSpace(true, -1);
		return true;
	}

	function readDocument()
	{
		var documentStart = position;
		var _position:Int;
		var directiveName:String;
		var directiveArgs:Array<String>;
		var hasDirectives = false;

		version = null;
		checkLineBreaks = false;
		tagMap = new StringMap();
		anchorMap = new StringMap();

		while (position < length)
		{
			skipSeparationSpace(true, -1);

			if (lineIndent > 0 || CHAR_PERCENT != character)
				break;

			hasDirectives = true;
			character = Utf8.charCodeAt(input, ++position);
			_position = position;

			while (position < length &&
				CHAR_SPACE != character &&
				CHAR_TAB != character &&
				CHAR_LINE_FEED != character &&
				CHAR_CARRIAGE_RETURN != character)
			{
				character = Utf8.charCodeAt(input, ++position);
			}

			directiveName = yaml.util.Utf8.substring(input, _position, position);
			directiveArgs = [];

			if (Utf8.length(directiveName) < 1)
				throwError('directive name must not be less than one character in length');

			while (position < length)
			{
				while (CHAR_SPACE == character || CHAR_TAB == character)
				{
					character = Utf8.charCodeAt(input, ++position);
				}

				if (CHAR_SHARP == character) 
				{
					do { character = Utf8.charCodeAt(input, ++position); }
					while (position < length && CHAR_LINE_FEED != character && CHAR_CARRIAGE_RETURN != character);
					break;
				}

				if (CHAR_LINE_FEED == character || CHAR_CARRIAGE_RETURN == character)
					break;

				_position = position;

				while (position < length &&
					CHAR_SPACE != character &&
					CHAR_TAB != character &&
					CHAR_LINE_FEED != character &&
					CHAR_CARRIAGE_RETURN != character)
				{
					character = Utf8.charCodeAt(input, ++position);
				}

				directiveArgs.push(yaml.util.Utf8.substring(input, _position, position));
			}

			if (position < length) 
			{
				readLineBreak();
			}

			if (directiveHandlers.exists(directiveName)) 
			{
				directiveHandlers.get(directiveName)(directiveName, directiveArgs);
			}
			else
			{
				throwWarning('unknown document directive "' + directiveName + '"');
			}
		}

		skipSeparationSpace(true, -1);

		if (0 == lineIndent &&
			CHAR_MINUS == character &&
			CHAR_MINUS == Utf8.charCodeAt(input, position + 1) &&
			CHAR_MINUS == Utf8.charCodeAt(input, position + 2))
		{
			position += 3;
			character = Utf8.charCodeAt(input, position);
			skipSeparationSpace(true, -1);

		}
		else if (hasDirectives)
		{
			throwError('directives end mark is expected');
		}

		composeNode(lineIndent - 1, CONTEXT_BLOCK_OUT, false, true);
		skipSeparationSpace(true, -1);

		if (validate && checkLineBreaks && PATTERN_NON_ASCII_LINE_BREAKS.match(yaml.util.Utf8.substring(input, documentStart, position)))
		{
			throwWarning('non-ASCII line breaks are interpreted as content');
		}

		output(result);

		if (position == lineStart && testDocumentSeparator())
		{
			if (CHAR_DOT == character)
			{
				position += 3;
				character = Utf8.charCodeAt(input, position);
				skipSeparationSpace(true, -1);
			}
			return;
		}

		if (position < length) 
		{
			throwError('end of the stream or a document separator is expected');
		} 
		else 
		{
			return;
		}
	}

	public static inline var KIND_STRING = 'string';
	public static inline var KIND_ARRAY  = 'array';
	public static inline var KIND_OBJECT = 'object';


	public static inline var CONTEXT_FLOW_IN   = 1;
	public static inline var CONTEXT_FLOW_OUT  = 2;
	public static inline var CONTEXT_BLOCK_IN  = 3;
	public static inline var CONTEXT_BLOCK_OUT = 4;


	public static inline var CHOMPING_CLIP  = 1;
	public static inline var CHOMPING_STRIP = 2;
	public static inline var CHOMPING_KEEP  = 3;


	public static inline var CHAR_TAB                  = 0x09;   /* Tab */
	public static inline var CHAR_LINE_FEED            = 0x0A;   /* LF */
	public static inline var CHAR_CARRIAGE_RETURN      = 0x0D;   /* CR */
	public static inline var CHAR_SPACE                = 0x20;   /* Space */
	public static inline var CHAR_EXCLAMATION          = 0x21;   /* ! */
	public static inline var CHAR_DOUBLE_QUOTE         = 0x22;   /* " */
	public static inline var CHAR_SHARP                = 0x23;   /* # */
	public static inline var CHAR_PERCENT              = 0x25;   /* % */
	public static inline var CHAR_AMPERSAND            = 0x26;   /* & */
	public static inline var CHAR_SINGLE_QUOTE         = 0x27;   /* ' */
	public static inline var CHAR_ASTERISK             = 0x2A;   /* * */
	public static inline var CHAR_PLUS                 = 0x2B;   /* + */
	public static inline var CHAR_COMMA                = 0x2C;   /* , */
	public static inline var CHAR_MINUS                = 0x2D;   /* - */
	public static inline var CHAR_DOT                  = 0x2E;   /* . */
	public static inline var CHAR_SLASH                = 0x2F;   /* / */
	public static inline var CHAR_DIGIT_ZERO           = 0x30;   /* 0 */
	public static inline var CHAR_DIGIT_ONE            = 0x31;   /* 1 */
	public static inline var CHAR_DIGIT_NINE           = 0x39;   /* 9 */
	public static inline var CHAR_COLON                = 0x3A;   /* : */
	public static inline var CHAR_LESS_THAN            = 0x3C;   /* < */
	public static inline var CHAR_GREATER_THAN         = 0x3E;   /* > */
	public static inline var CHAR_QUESTION             = 0x3F;   /* ? */
	public static inline var CHAR_COMMERCIAL_AT        = 0x40;   /* @ */
	public static inline var CHAR_CAPITAL_A            = 0x41;   /* A */
	public static inline var CHAR_CAPITAL_F            = 0x46;   /* F */
	public static inline var CHAR_CAPITAL_L            = 0x4C;   /* L */
	public static inline var CHAR_CAPITAL_N            = 0x4E;   /* N */
	public static inline var CHAR_CAPITAL_P            = 0x50;   /* P */
	public static inline var CHAR_CAPITAL_U            = 0x55;   /* U */
	public static inline var CHAR_LEFT_SQUARE_BRACKET  = 0x5B;   /* [ */
	public static inline var CHAR_BACKSLASH            = 0x5C;   /* \ */
	public static inline var CHAR_RIGHT_SQUARE_BRACKET = 0x5D;   /* ] */
	public static inline var CHAR_UNDERSCORE           = 0x5F;   /* _ */
	public static inline var CHAR_GRAVE_ACCENT         = 0x60;   /* ` */
	public static inline var CHAR_SMALL_A              = 0x61;   /* a */
	public static inline var CHAR_SMALL_B              = 0x62;   /* b */
	public static inline var CHAR_SMALL_E              = 0x65;   /* e */
	public static inline var CHAR_SMALL_F              = 0x66;   /* f */
	public static inline var CHAR_SMALL_N              = 0x6E;   /* n */
	public static inline var CHAR_SMALL_R              = 0x72;   /* r */
	public static inline var CHAR_SMALL_T              = 0x74;   /* t */
	public static inline var CHAR_SMALL_U              = 0x75;   /* u */
	public static inline var CHAR_SMALL_V              = 0x76;   /* v */
	public static inline var CHAR_SMALL_X              = 0x78;   /* x */
	public static inline var CHAR_LEFT_CURLY_BRACKET   = 0x7B;   /* { */
	public static inline var CHAR_VERTICAL_LINE        = 0x7C;   /* | */
	public static inline var CHAR_RIGHT_CURLY_BRACKET  = 0x7D;   /* } */


	public static var SIMPLE_ESCAPE_SEQUENCES:IntMap<String> = 
	{
		var hash = new IntMap<String>();
		hash.set(CHAR_DIGIT_ZERO, createUtf8Char(0x00));// '\x00');
		hash.set(CHAR_SMALL_A, createUtf8Char(0x07));//'\x07');
		hash.set(CHAR_SMALL_B, createUtf8Char(0x08));//'\x08');
		hash.set(CHAR_SMALL_T, createUtf8Char(0x09));//'\x09');
		hash.set(CHAR_TAB, createUtf8Char(0x09));//'\x09');
		hash.set(CHAR_SMALL_N, createUtf8Char(0x0A));//'\x0A');
		hash.set(CHAR_SMALL_V, createUtf8Char(0x0B));//'\x0B');
		hash.set(CHAR_SMALL_F, createUtf8Char(0x0C));//'\x0C');
		hash.set(CHAR_SMALL_R, createUtf8Char(0x0D));//'\x0D');
		hash.set(CHAR_SMALL_E, createUtf8Char(0x1B));//'\x1B');
		hash.set(CHAR_SPACE, createUtf8Char(0x20));//' ');
		hash.set(CHAR_DOUBLE_QUOTE, createUtf8Char(0x22));//'\x22');
		hash.set(CHAR_SLASH, createUtf8Char(0x2f));//'/');
		hash.set(CHAR_BACKSLASH, createUtf8Char(0x5C));//'\x5C');
		hash.set(CHAR_CAPITAL_N, createUtf8Char(0x85));//'\x85');
		hash.set(CHAR_UNDERSCORE, createUtf8Char(0xA0));//'\xA0');
		hash.set(CHAR_CAPITAL_L, createUtf8Char(0x2028));//'\u2028');
		hash.set(CHAR_CAPITAL_P, createUtf8Char(0x2029));//'\u2029');
		hash;
	};
	
	static function createUtf8Char(hex:Int):String
	{
		var utf8 = new Utf8(1);
		utf8.addChar(hex);
		return utf8.toString();
	}

	public static var HEXADECIMAL_ESCAPE_SEQUENCES:IntMap<Int> = 
	{
		var hash = new IntMap<Int>();
		hash.set(CHAR_SMALL_X, 2);
		hash.set(CHAR_SMALL_U, 4);
		hash.set(CHAR_CAPITAL_U, 8);
		hash;
	};

	#if (eval || neko || cpp || display)
	public static var PATTERN_NON_PRINTABLE         = ~/[\x{00}-\x{08}\x{0B}\x{0C}\x{0E}-\x{1F}\x{7F}-\x{84}\x{86}-\x{9F}\x{FFFE}\x{FFFF}]/u;
	#elseif (js || flash9 || java)
	public static var PATTERN_NON_PRINTABLE         = ~/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x84\x86-\x9F\uD800-\uDFFF\uFFFE\uFFFF]/u;	
	#else
	#error "Compilation target not supported due to lack of Unicode RegEx support."
	#end
	
	#if (eval || neko || cpp || display)
	public static var PATTERN_NON_ASCII_LINE_BREAKS = ~/[\x{85}\x{2028}\x{2029}]/u;
	#elseif (js || flash9 || java)
	public static var PATTERN_NON_ASCII_LINE_BREAKS = ~/[\x85\u2028\u2029]/u;
	#else
	#error "Compilation target not supported due to lack of Unicode RegEx support."
	#end
	
	public static var PATTERN_FLOW_INDICATORS       = ~/[,\[\]\{\}]/u;
	public static var PATTERN_TAG_HANDLE            = ~/^(?:!|!!|![a-z\-]+!)$/iu;
	public static var PATTERN_TAG_URI               = ~/^(?:!|[^,\[\]\{\}])(?:%[0-9a-f]{2}|[0-9a-z\-#;\/\?:@&=\+\$,_\.!~\*'\(\)\[\]])*$/iu;

}
