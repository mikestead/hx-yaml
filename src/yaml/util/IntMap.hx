package yaml.util;

#if haxe3
typedef IntMap<T> = haxe.ds.IntMap<T>;
#else
typedef IntMap<T> = IntHash<T>;
#end
