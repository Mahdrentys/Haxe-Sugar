package sugar;

import haxe.macro.Type;
import haxe.macro.Expr;

interface TypeProcessor
{
    public function processClass(classType:ClassType, fields:Array<Field>):Array<Field>;
    public function processEnum(enumType:EnumType, fields:Array<Field>):Array<Field>;
    public function processTypedef(defType:DefType, fields:Array<Field>):Array<Field>;
}