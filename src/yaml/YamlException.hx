package yaml;

import haxe.PosInfos;
import mcore.exception.Exception;

class YamlException extends Exception
{
    public function new(?message:String="", ?cause:Dynamic = null, ?info:PosInfos)
	{
		super(message, cause, info);
	}
}
