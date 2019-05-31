package tests;

import utest.Test;
import sugar.Container;

class A
{
    public var id:Int;

    public function new()
    {
        id = Std.random(1000000000);
    }
}

class A2
{
    public var id:Int;

    public function new(_id:Int)
    {
        id = _id;
    }
}

class B
{
    @inject
    public var a:A;

    public function new() {}
}

class B2
{
    public var a:A2;

    public function new(@inject _a:A2)
    {
        a = _a;
    }
}

class C
{
    @inject
    public var b:B;
    public var id:Int;

    public function new(_id:Int = 0)
    {
        id = _id;
    }
}

class C2
{
    public var b:B2;
    public var id:Int;

    public function new(@inject _b:B2, _id:Int = 0)
    {
        b = _b;
        id = _id;
    }

    public function test(@inject _b:B2, message:String):String
    {
        if (_b.a.id == null) _b.a.id = 20;
        return message + " " + Std.string(_b.a.id);
    }

    public static function staticTest(message:String, @inject b:B2):String
    {
        if (b.a.id == null) b.a.id = 20;
        return message + " " + Std.string(b.a.id);
    }
}

interface Interface
{
    public function test():String;
}

class Implementation implements Interface
{
    public function new() {}

    public function test():String
    {
        return "test";
    }
}

class ImplementationUser
{
    @inject
    public var implementation1:Interface;
    public var implementation2:Interface;

    public function new(@inject implementation:Interface)
    {
        implementation2 = implementation;
    }

    public function test():String
    {
        return implementation1.test() + implementation2.test();
    }
}

class Az
{

}

class DI extends Test
{
    public function specGet():Void
    {
        // C
        var c:C = null;

        for (i in 0...10)
        {
            var newC = Container.get(C);
            newC.id == 0;
            
            if (c != null)
            {
                newC.b.a.id == c.b.a.id;
            }

            c = newC;
        }

        // C2
        var c2:C2 = null;

        for (i in 0...10)
        {
            var newC2 = Container.get(C2);
            newC2.id == 0;
            
            if (c2 != null)
            {
                newC2.b.a.id == c2.b.a.id;
            }

            c2 = newC2;
        }
    }

    public function specSetValue():Void
    {
        // C
        Container.setValue(C, new C(3));
        var c = Container.get(C);
        c.id == 3;
        Container.remove(C);
        c = Container.get(C);
        c.id == 0;
    }

    public function specSetFactory():Void
    {
        Container.setFactory(C, function():C
        {
            return new C(Std.random(1000000000));
        });

        var c = Container.get(C);
        var id = c.id;

        for (i in 0...10)
        {
            c = Container.get(C);
            c.id == id;
        }
    }

    public function specBuild():Void
    {
        Container.build(C, function():C
        {
            return new C(Std.random(1000000000));
        });
        
        var c = Container.get(C);
        var id = c.id;

        for (i in 0...10)
        {
            c = Container.get(C);
            c.id != id;
        }
    }

    public function specAutoResolve():Void
    {
        var c:C = null;

        for (i in 0...10)
        {
            var newC = new C();
            newC.id == 0;
            
            if (c != null)
            {
                newC.b.a.id == c.b.a.id;
            }

            c = newC;
        }
    }

    public function specFunction():Void
    {
        var c = new C2();
        c.test("Hello") == "Hello 20";
        C2.staticTest("Hello") == "Hello 20";
    }

    public function specInterface():Void
    {
        var hasThrown = false;

        try
        {
            var a = new ImplementationUser();
            a.test() == "testtest";
        }
        catch (e:Dynamic)
        {
            hasThrown = true;
        }

        hasThrown == true;

        Container.setValue(Interface, Container.get(Implementation));
        var a = new ImplementationUser();
        a.test() == "testtest";
        Container.remove(Interface);

        Container.setFactory(Interface, function():Interface
        {
            return Container.get(Implementation);
        });

        var a = new ImplementationUser();
        a.test() == "testtest";
        Container.remove(Interface);

        Container.build(Interface, function():Interface
        {
            return Container.get(Implementation);
        });

        var a = new ImplementationUser();
        a.test() == "testtest";
        Container.remove(Interface);
    }
}