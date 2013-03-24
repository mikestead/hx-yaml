# Overview

A cross platform [YAML](http://www.yaml.org/) parser and renderer for Haxe. Ported from the fast and feature rich
[js-yaml](https://github.com/nodeca/js-yaml).

> Requires Neko 2.0+ when used under the Neko runtime due to its support for Unicode based regular expressions.

### Installation

- *Still in development, not ready for public use just yet.*
	
## API
	
#### Parsing

	yaml.Parser.ParserOptions:
		- strict:Bool     - Parser will throw errors instead of tracing warnings. Default `false`.
        - validate:Bool   - Perform validation checks while parsing. Default is `true`.
        - schema:Schema   - The schema to use. Default is `yaml.schema.DefaultSchema`.

	// Parse a single yaml document into object form
	yaml.Yaml.parse(document:String, ?options:ParserOptions):Dynamic
	
	// (sys only) Read a single yaml document from disk and parse it into object form
	yaml.Yaml.read(filePath:String, ?options:ParserOptions):Dynamic

#### Rendering

	yaml.Renderer.RendererOptions:
		- indent:Int        - The space indentation to use. Default `2`.
		- flowLevel:Int     - The level of nesting, when to switch from block to flow 
								style for collections. -1 means block style everywhere. Default `-1`.
		- styles:StringMap  - "tag" => "style" map. Each tag may have its own set of styles.
		- schema:Schema     - The schema to use. Default is `yaml.schema.DefaultSchema`.
		
	// Render a yaml object graph as a yaml document
	yaml.Yaml.render(data:Dynamic, ?options:RenderOptions):String
	
	// (sys only) Render a yaml object graph as a yaml document and write it to disk
	yaml.Yaml.write(data:Dynamic, filePath:String, ?options:RenderOptions):Void
	

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
!!omap [ ... ]              # Array of Maps
!!pairs [ ... ]             # Array of Array pairs
!!set { ... }               # Map of keys with null values
!!str '...'                 # String
!!seq [ ... ]               # Array
!!map { ... }               # Map
```
