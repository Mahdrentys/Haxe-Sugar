package sugar;

import haxe.macro.Expr;
import haxe.macro.Type;
using haxe.EnumTools.EnumValueTools;

class DefaultArgs implements TypeProcessor
{
    public function new() {}

    public function processClass(classType:ClassType, fields:Array<Field>):Array<Field>
    {
        var newFields:Array<Field> = [];

        for (field in fields)
        {
            if (field.kind.match(FFun(_)))
            {
                var func:Function = field.kind.getParameters()[0];
                var newArgs:Array<FunctionArg> = [];

                for (arg in func.args)
                {
                    if (arg.value != null)
                    {
                        var defaultValue = arg.value.expr;

                        function isConstant(expr:ExprDef):Bool
                        {
                            if (!expr.match(EConst(_))) return false;
                            var constant:Constant = expr.getParameters()[0];
                            if (constant.match(CRegexp(_, _))) return false;

                            if (constant.match(CIdent(_)))
                            {
                                var identifier:String = constant.getParameters()[0];
                                if (identifier != "true" && identifier != "false") return false;
                            }

                            return true;
                        }

                        if (!isConstant(defaultValue))
                        {
                            arg.value = macro null;
                            if (func.expr == null) func.expr = {expr: EBlock([]), pos: field.pos};
                            var exprs:Array<Expr> = func.expr.expr.getParameters()[0];
                            exprs.reverse();

                            var argName = arg.name;
                            var expr = macro if ($i{argName} == null) $i{argName} = ${{expr: defaultValue, pos: field.pos}};
                            expr.pos = field.pos;
                            exprs.push(expr);

                            exprs.reverse();
                            func.expr.expr = EBlock(exprs);
                        }
                    }

                    newArgs.push(arg);
                }

                func.args = newArgs;
                field.kind = FFun(func);
            }
            
            newFields.push(field);
        }

        return newFields;

        return null;
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