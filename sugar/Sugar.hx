package sugar;

import haxe.macro.Expr;
import haxe.macro.Compiler;
import haxe.macro.Context;

class Sugar
{
    macro public static function init(path:String):Expr
    {
        Compiler.addGlobalMetadata(path, "@:build(sugar.Sugar.build())");
        return macro{};
    }

    macro public static function build():Array<Field>
    {
        var fields = Context.getBuildFields();
        return fields;
    }
}