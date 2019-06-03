package sugar;

import haxe.macro.Expr;
import haxe.macro.Context;
using haxe.EnumTools.EnumValueTools;

class Fallback implements ExprProcessor
{
    public function new() {}

    public function process(expr:Expr):Expr
    {
        #if (macro || eval)
            if (expr.expr.match(EMeta(_, _)))
            {
                var meta:MetadataEntry = expr.expr.getParameters()[0];
                var subExpr:Expr = expr.expr.getParameters()[1];

                if (meta.name == "fallback")
                {
                    if (subExpr.expr.match(EArrayDecl(_)))
                    {
                        var exprs:Array<Expr> = subExpr.expr.getParameters()[0];
                        
                        if (exprs.length == 0)
                        {
                            Context.error("@fallback array must be not empty.", expr.pos);
                        }

                        var firstExpr = exprs.shift();
                        var fallbackExpr:Expr;

                        if (exprs.length > 0)
                        {
                            fallbackExpr = process(
                            {
                                expr: EMeta({name: "fallback", pos: expr.pos}, {expr: EArrayDecl(exprs), pos: expr.pos}),
                                pos: expr.pos
                            });
                        }
                        else
                        {
                            fallbackExpr = macro null;
                        }

                        expr.expr = ETernary(macro ${firstExpr} != null, firstExpr, fallbackExpr);
                    }
                    else
                    {
                        Context.error("@fallback metadata must be followed by an array declaration.", expr.pos);
                    }
                }
            }

            return expr;
        #else
            return expr;
        #end
    }
}