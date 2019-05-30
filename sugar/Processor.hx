package sugar;

import haxe.macro.Type;
import haxe.macro.Expr;

interface Processor
{
    public function process(classType:ClassType, fields:Array<Field>):Array<Field>;
}