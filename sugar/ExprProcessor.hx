package sugar;

import haxe.macro.Expr;

interface ExprProcessor
{
    public function process(expr:Expr):Expr;
}