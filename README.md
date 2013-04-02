# Overview

A cross platform [YAML](http://www.yaml.org/) 1.2 parser and renderer for Haxe. Ported from the feature rich
[js-yaml](https://github.com/nodeca/js-yaml). Currently supports JavaScript, Flash (as3) and Neko 2.0+.

### Installation

From haxelib:

	haxelib install yaml
	
Or the latest directly from GitHub

	haxelib git yaml https://github.com/mikestead/hx-yaml.git src
	
## Example

#### invoice.yaml

``` yml
invoice: 34843
date   : 2001-01-23
bill_to: &id001
  given  : Chris
  family : Dumars
  address:
    lines: |
      458 Walkman Dr.
      Suite #292
    city    : Royal Oak
    state   : MI
    postal  : 48046
ship_to: *id001
tax  : 251.42
457: true
total: 4443.52
comments: >
  Late afternoon is best.
  Backup contact is Nancy
  Billsmer @ 338-4338.
```

#### Example.hx

``` haxe
import yaml.Yaml;
import yaml.Parser;
import yaml.Renderer;
import yaml.util.ObjectMap;

class Example
{
	static function main()
	{
		parsingExample();
		renderingExample();
	}

	static function parsingExample()
	{
		#if sys
		// Load and parse our invoice document using yaml.util.ObjectMap for key => value containers.
		// Using this default option allows for complex key types and a slightly nicer api to 
		// iterate keys/values. 
		// Equivalent to Yaml.read("invoice.yaml", Parser.options().useMaps());
		var data:AnyObjectMap = Yaml.read("invoice.yaml"); 

		trace(data.get("tax")); // 251.42
		trace(data.get(457)); // true
		
		// Load and parse the same document this time using dynamic objects for key => value containers.
		// This option will stringify all keys but is useful for mapping to typedefs.
		var data = Yaml.read("invoice.yaml", Parser.options().useObjects());
		
		trace(data.invoice); // 3483
		trace(data.ship_to.given); // Chris
		trace(Reflect.field(data, "457")); // true
		#end
		
		// If you already have the yaml document in string form you can parse it directly
		var data = Yaml.parse("key: value");
		
		trace(data.get("key")); // value
	}

	static function renderingExample()
	{
		var receipt = {assistant:"Chris", items:[{rice:2.34}, {milk:1.22}]};

		// Render an object tree as a yaml document.
		var document = Yaml.render(receipt);
		trace(document);

		//  assistant: Chris
		//  items:
		//      - rice: 2.34
		//      - milk: 1.22

		#if sys
		// This time write that same document to disk and adjust the flow level giving 
		// a more compact result.
		Yaml.write("receipt.yaml", receipt, Renderer.options().setFlowLevel(1));
		#end
	}
}
```

#### receipt.yaml

``` yml
assistant: Chris
items: [{rice: 2.34}, {milk: 1.22}]
```

## API

#### Parsing

``` none
// Parse a single yaml document into object form
yaml.Yaml.parse(document:String, ?options:ParserOptions):Dynamic

// (sys only) Read a single yaml document from disk and parse it into object form
yaml.Yaml.read(filePath:String, ?options:ParserOptions):Dynamic

yaml.Parser.ParserOptions:
	- strict:Bool     - Parser will throw errors instead of tracing warnings. Default `false`.
    - validate:Bool   - Perform validation checks while parsing. Default is `true`.
    - schema:Schema   - The schema to use. Default is `yaml.schema.DefaultSchema`.
    - maps:Boolean    - True when using ObjectMaps, false when using Dynamic objects.
```

#### Rendering

``` none
// Render a yaml object graph as a yaml document
yaml.Yaml.render(data:Dynamic, ?options:RenderOptions):String

// (sys only) Render a yaml object graph as a yaml document and write it to disk
yaml.Yaml.write(filePath:String, data:Dynamic, ?options:RenderOptions):Void

yaml.Renderer.RendererOptions:
	- indent:Int        - The space indentation to use. Default `2`.
	- flowLevel:Int     - The level of nesting, when to switch from block to flow 
							style for collections. -1 means block style everywhere. Default `-1`.
	- styles:StringMap  - "tag" => "style" map. Each tag may have its own set of styles.
	- schema:Schema     - The schema to use. Default is `yaml.schema.DefaultSchema`.
```

##### Rendering Styles

``` none
!!null
  "canonical"   => "~"

!!int
  "binary"      => "0b1", "0b101010", "0b1110001111010"
  "octal"       => "01", "052", "016172"
  "decimal"     => "1", "42", "7290"
  "hexadecimal" => "0x1", "0x2A", "0x1C7A"

!!null, !!bool, !!float
  "lowercase"   => "null", "true", "false", ".nan", '.inf'
  "uppercase"   => "NULL", "TRUE", "FALSE", ".NAN", '.INF'
  "camelcase"   => "Null", "True", "False", ".NaN", '.Inf'
```

By default, !!int uses `decimal`, and !!null, !!bool, !!float use `lowercase`.

## Supported YAML types

The list of standard YAML tags and corresponding Haxe types. See also
[YAML types](http://yaml.org/type/).

```
!!null ''                   # null
!!bool 'yes'                # Bool
!!int '3...'                # Int
!!float '3.14...'           # Float
!!binary '...base64...'     # haxe.Binary
!!timestamp 'YYYY-...'      # Date
!!omap [ ... ]              # Array of yaml.util.ObjectMap
!!pairs [ ... ]             # Array of Array pairs
!!set { ... }               # yaml.util.ObjectMap of keys with null values
!!str '...'                 # String
!!seq [ ... ]               # Array
!!map { ... }               # yaml.util.ObjectMap
```

When parsing maps, [yaml.util.ObjectMap](https://github.com/mikestead/hx-yaml/blob/master/src/yaml/util/ObjectMap.hx) 
is used. Under Haxe 3.0 `haxe.ds.ObjectMap` *would* be used but it doesn't support primitive
keys on all targets and we need a map which can contain a mixture of key types.

## Limitations

- Under Neko UTC date translation is not yet possible so dates will be represented in local time instead.
- Requires Neko 2.0+ when used under the Neko runtime due to its support for Unicode based regular expressions.
- CPP does not yet support Unicode based regular expressions so is not yet a supported target.

## License

MIT - [See LICENSE](https://github.com/mikestead/hx-yaml/blob/master/LICENSE) 
