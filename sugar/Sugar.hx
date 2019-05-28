package sugar;

import haxe.macro.Expr;
import haxe.macro.Compiler;
import haxe.macro.Context;

class Sugar
{
    macro public static function use(packageFilter:String):Void
    {
        Compiler.addGlobalMetadata(packageFilter, "@:build(sugar.Sugar.build())");
    }

    macro public static function build():Array<Field>
    {
        var fields = Context.getBuildFields();
        return fields;
    }
}