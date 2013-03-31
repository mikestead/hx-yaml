package yaml.util;

import haxe.ds.IntMap;
import haxe.ds.StringMap;
import haxe.ds.ObjectMap;

private enum MapType
{
	MapInt;
	MapString;
	MapObject;
}

class MapWrapper<K, V>
{
	var map:Dynamic;
	var type:MapType;

    public function new(map:Dynamic)
	{
		this.map = map;
		type = getType();
	}
	
	function getType()
	{
		if (Std.is(map, IntMap)) return MapInt;
		else if (Std.is(map, StringMap)) return MapString;
		else if (Std.is(map, ObjectMap)) return MapObject;
		else throw "Unsupported map type " + map;
	}

	public function set(key:K, value:V):Void
	{
		#if flash9
		if (type == MapObject)
		{
			untyped map[key] = value;
			return;
		}
		#elseif neko
		switch (type)
		{
			case MapInt: untyped __dollar__hset(map.h, key, value, null);
			case MapString: untyped __dollar__hset(map.h, key.__s, value, null);
			case MapObject:
				var id = untyped key.__id__;
				if (id == null)
				{
					untyped ObjectMap.count++;
					id = untyped key.__id__ =  ObjectMap.count;
				}
				untyped __dollar__hset(map.h, id, value, null);
				untyped __dollar__hset(map.k, id, key, null);
		}
		return;
		#elseif cpp
		if (type == MapObject)
		{
			untype map.__Internal.set( untyped __global__.__hxcpp_obj_id(key), value);
			return;
		}
		#end
		
		map.set(key, value);
	}

	public function get(key:K):Null<V>
	{
		#if flash9
		if (type == MapObject)
			return untyped map[key];
		#elseif flash8
		if (type == MapObject)
			return untyped map.h["$" + untyped key.__id__];
		#elseif js
		if (type == MapObject)
			return untyped map.h[untyped key.__id__];
		#elseif neko
		if (type == MapString)
			return untyped __dollar__hget(map.h, key.__s, null);
		#end
		
		return map.get(key);
	}

	public function exists(key:K):Bool
	{
		#if flash9
		if (type == MapObject)
			return untyped map[key] != null;
		#elseif flash8
		if (type == MapObject)
			return untyped h["$" + untyped key.__id__];
		#elseif js
		if (type == MapString)
			return untyped map.h.hasOwnProperty(untyped key.__id__);
		#elseif neko
		return switch (type)
		{
			case MapInt: untyped __dollar__hmem(map.h, key, null);
			case MapString: untyped __dollar__hmem(map.h, untyped key.__s, null);
			case MapObject: untyped __dollar__hmem(map.h, untyped key.__id__, null);
		}
		#elseif cpp
		if (type == MapObject)
			return untyped map.__Internal.exists( untyped __global__.__hxcpp_obj_id(key) );
		#end
		
		return map.exists(key);
	}

	public function remove(key:K):Bool
	{
		#if neko
		if (type == MapInt)
			return untyped __dollar__hremove(map.h, key, null);
		else if (type == MapString)
			return untyped __dollar__hremove(map.h, untyped key.__s, null);
		#elseif cpp
		if (type == MapInt)
			return untyped map.__Internal.remove(untyped __global__.__hxcpp_obj_id(key));
		#end
		return map.remove(key);
	}

	public function keys():Iterator<K>
	{
		#if php
		return untyped __call__("new _hx_array_iterator", __call__("array_values", map.hk));
		#end
		return map.keys();
	}

	public function iterator():Iterator<V>
	{
		#if php
		return untyped __call__("new _hx_array_iterator", __call__("array_values", map.h));
		#end
		return map.iterator();
	}

	public function toString():String
	{
		return map.toString();
	}
}
