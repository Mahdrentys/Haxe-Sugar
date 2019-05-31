package sugar;

import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;
using Type;
using haxe.EnumTools.EnumValueTools;

class Container implements Processor
{
    private static var instances = new Map<String, Dynamic>();
    private static var factories = new Map<String, Void->Dynamic>();
    private static var buildFunctions = new Map<String, Void->Dynamic>();

    public function new() {}

    public function processClass(classType:ClassType, fields:Array<Field>):Array<Field>
    {
        #if neko
            if (!classType.isInterface)
            {
                var newFields:Array<Field> = [];

                function hasInjectMetadata(metas:Array<MetadataEntry>):Bool
                {
                    if (metas == null) return false;

                    for (meta in metas)
                    {
                        if (meta.name == "inject") return true;
                    }

                    return false;
                }

                for (field in fields)
                {
                    if (field.kind.match(FFun(_)))
                    {
                        // field is a function
                        var func:Function = field.kind.getParameters()[0];
                        if (func.expr == null) func.expr = {expr: EBlock([]), pos: field.pos};
                        var exprs:Array<Expr> = func.expr.expr.getParameters()[0];
                        exprs.reverse();
                        var newArgs:Array<FunctionArg> = [];

                        for (arg in func.args)
                        {
                            if (hasInjectMetadata(arg.meta))
                            {
                                if (arg.type == null)
                                {
                                    Context.error("Argument must have an explicit type with an @inject metadata", field.pos);
                                    newArgs.push(arg);
                                    continue;
                                }

                                var argType = Context.resolveType(arg.type, field.pos);

                                if (!argType.match(TInst(_)))
                                {
                                    Context.error("Variable type must be a class with @inject metadata.", field.pos);
                                    newFields.push(field);
                                    continue;
                                }

                                var argClassType:ClassType = argType.getParameters()[0].get();
                                var className = "";

                                for (i in 0...argClassType.pack.length)
                                {
                                    if (i == 0)
                                    {
                                        className += argClassType.pack[i];
                                    }
                                    else
                                    {
                                        className += "." + argClassType.pack[i];
                                    }
                                }

                                className += className == "" ? argClassType.name : ("." + argClassType.name);
                                var variableName = arg.name;
                                exprs.push(macro var $variableName = sugar.Container.getByClassName($v{className}, $v{argClassType.isInterface}));
                            }
                            else
                            {
                                newArgs.push(arg);
                            }
                        }

                        func.args = newArgs;
                        exprs.reverse();
                        func.expr.expr = EBlock(exprs);
                    }
                    else if (field.kind.match(FVar(_, _)) && hasInjectMetadata(field.meta))
                    {
                        // field is a variable
                        var type:Null<ComplexType> = field.kind.getParameters()[0];

                        if (type == null)
                        {
                            Context.error("Variable must have an explicit type with an @inject metadata.", field.pos);
                            newFields.push(field);
                            continue;
                        }

                        var variableType = Context.resolveType(type, field.pos);

                        if (!variableType.match(TInst(_)))
                        {
                            Context.error("Variable type must be a class with @inject metadata.", field.pos);
                            newFields.push(field);
                            continue;
                        }

                        var variableClassType:ClassType = variableType.getParameters()[0].get();
                        var className = "";

                        for (i in 0...variableClassType.pack.length)
                        {
                            if (i == 0)
                            {
                                className += variableClassType.pack[i];
                            }
                            else
                            {
                                className += "." + variableClassType.pack[i];
                            }
                        }

                        className += className == "" ? variableClassType.name : ("." + variableClassType.name);
                        field.kind = FVar(type, macro sugar.Container.getByClassName($v{className}, $v{variableClassType.isInterface}));
                    }
                    else if (hasInjectMetadata(field.meta))
                    {
                        Context.error("A property with accessors can't have an @inject metadata.", field.pos);
                        newFields.push(field);
                        continue;
                    }

                    newFields.push(field);
                }

                return newFields;
            }

            return null;
        #else
            return [];
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

    public static function get<T>(classType:Class<T>, isInterface = false):T
    {
        var className = classType.getClassName();

        if (instances.exists(className))
        {
            return instances[className];
        }
        else if (factories.exists(className))
        {
            instances[className] = factories[className]();
            return instances[className];
        }
        else if (buildFunctions.exists(className))
        {
            return buildFunctions[className]();
        }
        else if (!isInterface)
        {
            instances[className] = classType.createInstance([]);
            return instances[className];
        }
        else
        {
            throw "Sugar DI Container: Interface \"" + classType.getClassName() + "\" was not setted.";
            return null;
        }
    }

    public static function getByClassName(className:String, isInterface = false):Dynamic
    {
        return get(className.resolveClass(), isInterface);
    }

    public static function setValue<T>(classType:Class<T>, value:T):Void
    {
        remove(classType);
        instances[classType.getClassName()] = value;
    }

    public static function setFactory<T>(classType:Class<T>, value:Void->T):Void
    {
        remove(classType);
        factories[classType.getClassName()] = value;
    }

    public static function build<T>(classType:Class<T>, value:Void->T):Void
    {
        remove(classType);
        buildFunctions[classType.getClassName()] = value;
    }

    public static function remove(classType:Class<Dynamic>):Void
    {
        var className = classType.getClassName();
        instances.remove(className);
        factories.remove(className);
        buildFunctions.remove(className);
    }
}