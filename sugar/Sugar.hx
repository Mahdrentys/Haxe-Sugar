package sugar;

import haxe.macro.Expr;
import haxe.macro.Compiler;
import haxe.macro.Context;

class Sugar
{
    private static var processors:Array<Processor> = [];

    macro public static function use(packageFilter:String):Void
    {
        Compiler.addGlobalMetadata(packageFilter, "@:build(sugar.Sugar.build())");
    }

    macro public static function build():Array<Field>
    {
        var classType = Context.getLocalClass().get();
        var fields = Context.getBuildFields();

        for (processor in processors)
        {
            fields = processor.process(classType, fields);
        }

        return fields;
    }
}