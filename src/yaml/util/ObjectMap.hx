package yaml.util;

typedef AnyObjectMap = ObjectMap<{}, Dynamic>;

#if haxe3
// under haxe 3 use built in map for speed, even though this prevents us using a null key.
typedef ObjectMap<K:{}, V> = haxe.ds.ObjectMap<K, V>;
#else
typedef ObjectMap<K:{}, V> = TObjectMap<K, V>;

/**
Cross platform object map which also supports the option of one null key.

Not very efficient but shouldn't be noticeable unless the data set becomes large.
*/
class TObjectMap<K:{}, V> 
{
	var _keys:Array<K>;
	var values:Array<V>;

	public function new(?weakKeys:Bool = false)
	{
		_keys = [];
		values = [];
	}

	public function set(key:K, value:V):Void
	{
		for (i in 0..._keys.length)
		{
			if (_keys[i] == key)
			{
				_keys[i] = key;
				values[i] = value;
				return;
			}
		}
		_keys.push(key);
		values.push(value);
	}

	public function get(key:K):Null<V>
	{
		for (i in 0..._keys.length)
		{
			if (_keys[i] == key)
				return values[i];
		}
		return null;
	}

	public function exists(key:K):Bool
	{
		for (k in _keys)
			if (k == key)
				return true;
		return false;
	}

	public function remove(key:K):Bool
	{
		for (i in 0..._keys.length)
		{
			if (_keys[i] == key)
			{
				_keys.splice(i, 1);
				values.splice(i, 1);
				return true;
			}
		}
		return false;
	}

	public function keys():Iterator<K>
	{
		return _keys.iterator();
	}

	public function iterator():Iterator<V>
	{
		return values.iterator();
	}

	public function toString():String
	{
		var s = "{";
		var ks:Dynamic = _keys;
		var vs:Dynamic = values;
		for (i in 0..._keys.length)
		{
			var k = (Type.getClass(ks[i]) == Array) ? "[" + ks[i] + "]" : ks[i];
			var v = (Type.getClass(vs[i]) == Array) ? "[" + vs[i] + "]" : vs[i];
			s += k + " => " + v + ", ";
		}

		if (_keys.length > 0)
			s = s.substr(0, s.length - 2);

		return s + "}";
	}
}
#end
