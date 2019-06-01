package sugar;

import haxe.macro.Expr;
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Type;

class Sugar
{
    private static var processors:Array<Processor> = [new DefaultArgs(), new Container()];

    macro public static function use(packageFilter:String):Void
    {
        Compiler.addGlobalMetadata(packageFilter, "@:build(sugar.Sugar.build())");
    }

    macro public static function build():Array<Field>
    {
        var fields = Context.getBuildFields();
        var classTypeRef = Context.getLocalClass();
        
        if (classTypeRef != null)
        {
            var classType:ClassType = classTypeRef.get();

            for (processor in processors)
            {
                fields = processor.processClass(classType, fields);
            }
        }
        else
        {
            var type = Context.getLocalType();
            if (type == null) return null;

            if (type.match(TEnum(_, _)))
            {
                var enumTypeRef:Ref<EnumType> = type.getParameters()[0];
                
                for (processor in processors)
                {
                    var newFields = processor.processEnum(enumTypeRef.get(), fields);
                    fields = newFields != null ? newFields : fields;
                }
            }
            else if (type.match(TType(_, _)))
            {
                var defTypeRef:Ref<DefType> = type.getParameters()[0];
                
                for (processor in processors)
                {
                    var newFields = processor.processTypedef(defTypeRef.get(), fields);
                    fields = newFields != null ? newFields : fields;
                }
            }
        }

        return fields;
    }
}