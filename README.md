# Overview

A cross platform [YAML](http://www.yaml.org/) 1.2 parser and renderer for Haxe. Ported from the fast and feature rich
[js-yaml](https://github.com/nodeca/js-yaml). Currently supports JS, AS3 and Neko 2.0+.

### Installation

From haxelib:

	haxelib install yaml
	
Or the latest directly from GitHub

	haxelib git yaml https://github.com/mikestead/hx-yaml.git src
	
## API

#### Parsing

	// Parse a single yaml document into object form
	yaml.Yaml.parse(document:String, ?options:ParserOptions):Dynamic
	
	// (sys only) Read a single yaml document from disk and parse it into object form
	yaml.Yaml.read(filePath:String, ?options:ParserOptions):Dynamic
	
	yaml.Parser.ParserOptions:
		- strict:Bool     - Parser will throw errors instead of tracing warnings. Default `false`.
        - validate:Bool   - Perform validation checks while parsing. Default is `true`.
        - schema:Schema   - The schema to use. Default is `yaml.schema.DefaultSchema`.

#### Rendering

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
is used. Under Haxe 3.0 `haxe.ds.ObjectMap` would be used but it doesn't support primitive
keys on all targets and we need a map which can contain a mixture of key types.

## Limitations

- Under Neko UTC date translation is not yet possible so dates will be represented in local time instead.
- Requires Neko 2.0+ when used under the Neko runtime due to its support for Unicode based regular expressions.
- CPP does not yet support Unicode based regular expressions so is not yet a supported target.

## License

MIT - [See LICENSE](https://github.com/mikestead/hx-yaml/blob/master/LICENSE) 
