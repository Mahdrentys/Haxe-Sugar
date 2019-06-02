package sugar;

import haxe.macro.Expr;
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Type;
using haxe.EnumTools.EnumValueTools;

private class FunctionBodyProcessor implements TypeProcessor
{
    private var processors:Array<ExprProcessor> = [new Fallback()];

    public function new() {}

    private function processExpr(expr:Expr):Expr
    {
        if (expr == null) return null;

        switch (expr.expr)
        {
            case EArray(e1, e2): expr.expr = EArray(processExpr(e1), processExpr(e2));
            case EBinop(op, e1, e2): expr.expr = EBinop(op, processExpr(e1), processExpr(e2));
            case EField(e, field): expr.expr = EField(processExpr(e), field);
            case EParenthesis(e): expr.expr = EParenthesis(processExpr(e));
            case EObjectDecl(fields):
                expr.expr = EObjectDecl(fields.map(function(field)
                {
                    field.expr = processExpr(field.expr);
                    return field;
                }));
            case ECall(e, params): expr.expr = ECall(processExpr(e), params.map(function(e1) return processExpr(e1)));
            case ENew(t, params): expr.expr = ENew(t, params.map(function(e) return processExpr(e)));
            case EUnop(op, postFix, e): expr.expr = EUnop(op, postFix, processExpr(e));
            case EVars(vars):
                expr.expr = EVars(vars.map(function(var1)
                {
                    var1.expr = processExpr(var1.expr);
                    return var1;
                }));
            case EFunction(name, func):
                func.expr = processExpr(func.expr);
                func.args = func.args.map(function(arg)
                {
                    arg.value = processExpr(arg.value);
                    return arg;
                });
                expr.expr = EFunction(name, func);
            case EBlock(exprs): expr.expr = EBlock(exprs.map(function(e) return processExpr(e)));
            case EFor(e1, e2): expr.expr = EFor(processExpr(e1), processExpr(e2));
            case EIn(e1, e2): expr.expr = EIn(processExpr(e1), processExpr(e2));
            case EIf(e1, e2, e3): expr.expr = EIf(processExpr(e1), processExpr(e2), processExpr(e3));
            case EWhile(e1, e2, normalWhile): expr.expr = EWhile(processExpr(e1), processExpr(e2), normalWhile);
            case ESwitch(e, cases, edef):
                expr.expr = ESwitch(processExpr(e), cases.map(function(c)
                {
                    c.expr = processExpr(c.expr);
                    c.guard = processExpr(c.guard);
                    c.values = c.values.map(function(value) return processExpr(value));
                    return c;
                }), processExpr(edef));
            case ETry(e, catches):
                expr.expr = ETry(processExpr(e), catches.map(function (c)
                {
                    c.expr = processExpr(c.expr);
                    return c;
                }));
            case EReturn(e): expr.expr = EReturn(processExpr(e));
            case EUntyped(e): expr.expr = EUntyped(processExpr(e));
            case EThrow(e): expr.expr = EThrow(processExpr(e));
            case ECast(e, t): expr.expr = ECast(processExpr(e), t);
            case EDisplay(e, isCall): expr.expr = EDisplay(processExpr(e), isCall);
            case ETernary(e1, e2, e3): expr.expr = ETernary(processExpr(e1), processExpr(e2), processExpr(e3));
            case ECheckType(e, t): expr.expr = ECheckType(processExpr(e), t);
            case EMeta(meta, e):
                if (meta.params != null) meta.params = meta.params.map(function(param) return processExpr(param));
                expr.expr = EMeta(meta, processExpr(e));
            default:
        }

        for (processor in processors)
        {
            expr = processor.process(expr);
        }

        return expr;
    }

    public function processClass(classType:ClassType, fields:Array<Field>):Array<Field>
    {
        #if (macro || eval)
            if (!classType.isInterface)
            {
                var newFields:Array<Field> = [];

                for (field in fields)
                {
                    if (field.kind.match(FFun(_)))
                    {
                        var func:Function = field.kind.getParameters()[0];
                        if (func.expr == null) func.expr = {expr: EBlock([]), pos: field.pos};
                        var exprs:Array<Expr> = func.expr.expr.getParameters()[0];
                        exprs = exprs.map(function(expr) return processExpr(expr));
                        func.expr.expr = EBlock(exprs);
                        field.kind = FFun(func);
                    }

                    newFields.push(field);
                }

                return newFields;
            }

            return null;
        #else
            return null;
        #end
    }

    public function processEnum(enumType:EnumType, fields:Array<Field>):Array<Field>
    {
        return null;
    }

    public function processTypedef(defType:DefType, fields:Array<Field>):Array<Field>
    {
        return null;
    }
}

class Sugar
{
    private static var processors:Array<TypeProcessor> = [new FunctionBodyProcessor(), new DefaultArgs(), new Container()];

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
                var newFields = processor.processClass(classType, fields);
                fields = newFields != null ? newFields : fields;
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