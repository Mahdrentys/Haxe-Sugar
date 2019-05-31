package sugar;

import haxe.macro.Expr;
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Type;

class Sugar
{
    private static var processors:Array<Processor> = [new Container()];

    macro public static function use(packageFilter:String):Void
    {
        Compiler.addGlobalMetadata(packageFilter, "@:build(sugar.Sugar.build())");
    }

    macro public static function build():Array<Field>
    {
        var classTypeRef = Context.getLocalClass();
        var classType:ClassType = classTypeRef != null ? classTypeRef.get() : null;
        var fields = Context.getBuildFields();

        for (processor in processors)
        {
            fields = processor.process(classType, fields);
        }

        return fields;
    }
}