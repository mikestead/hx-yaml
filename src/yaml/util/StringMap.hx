package yaml.util;

#if haxe3
typedef StringMap<T> = haxe.ds.StringMap<T>;
#else
typedef StringMap<T> = Hash<T>;
#end
