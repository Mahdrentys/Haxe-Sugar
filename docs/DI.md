# Dependency Injection

Sugar provides its own dependency injection container, through simple functions, or through metadata (aka "annotations" in other languages).

## Through simple functions

You can get instances of a class through the `sugar.Container.get` static method.

```haxe
import sugar.Container;

class MyAwesomeClass
{
    public function new() {}
}

var a:MyAwesomeClass = Container.get(MyAwesomeClass);
```

If you call this method multiple times, you will always get the same instance:

```haxe
import sugar.Container;

class MyAwesomeClass
{
    public var id:Int;

    public function new()
    {
        id = Std.random(1000000000);
    }
}

var a1 = Container.get(MyAwesomeClass);
var a2 = Container.get(MyAwesomeClass);
var a3 = Container.get(MyAwesomeClass);
a1.id == a2.id; // returns true
a1.id == a3.id; // returns true
```

If the class constructor has arguments, you have to set how to create an instance beforehand. For this, there is three methods. Let's consider this `Character` class:

```haxe
import sugar.Container;

class Character
{
    public var name:String;

    public function new(_name:String)
    {
        name = _name;
    }
}
```

You can't use `sugar.Container.get(Character)` before having set how to create the instance.

**First method:** Set directly the instance value:

```haxe
Container.setValue(Character, new Character("John"));
// Now, you can do:
var character = Container.get(Character);
character.name == "John"; // returns true
```

**Second method:** Set how to create the instance:

```haxe
Container.setSingleton(Character, function():Character
{
    return new Character("John");
});
```

The same instance will be returned each time you call `sugar.Container.get(Character)`, but the difference is that the instance will be created the first time you call `sugar.Container.get(Character)`, by calling the function you gived as second argument (but it will be called only a single time, and next the value will be stored). So the instance is created only if needed. It's useful for cases when the instanciation takes much time.

**Third method:** If you want to build a new instance each time you call `sugar.Container.get(Character)`, you can do this:

```haxe
Container.build(Character, function():Character
{
    return new Character("John");
});
```

Finally, you can delete a class instance, or a build function, by using:

```haxe
Container.remove(Character);
```

It will delete the stored instance, or the function given in `sugar.Container.build`.

## Through metadata

### Class attributes injection

You can automatically instanciate class attributes with the `@inject` metadata.

Let's consider a `Database` class, which needs a `Connection` instance as dependency, which itself needs a `TCPClient` instance as dependency:

```haxe
import sugar.Container;

class TCPClient
{
    public function new() {}

    public function connect(host:String, port:Int):Void
    {
        // Code...
    }
}

class Connection
{
    public var databaseName:String;
    public var host:String;
    public var port:Int;
    public var password:String;
    private var tcpClient:TCPClient;

    public function new(_databaseName:String, _host:String, _port:Int, _password:String)
    {
        databaseName = _databaseName;
        host = _host;
        port = _port;
        password = _password;
        tcpClient = new TCPClient();
        tcpClient.connect(host, port);
    }
}

class Database
{
    public var connection:Connection;

    public function new() {}

    public function query(sqlQuery:String)
    {
        // Code...
    }
}
```

You can automate the instanciation of the `TCPClient` in the `Connection` class, with the `@inject` metadata:

```haxe
class Connection
{
    public var databaseName:String;
    public var host:String;
    public var port:Int;
    public var password:String;
    @inject
    private var tcpClient:TCPClient;

    public function new(_databaseName:String, _host:String, _port:Int, _password:String)
    {
        databaseName = _databaseName;
        host = _host;
        port = _port;
        password = _password;
        tcpClient.connect(host, port);
    }
}
```

`tcpClient` attribute is automatically instanciated because the constructor of `TCPClient` does not have any arguments. As well, you can automate the instanciation of the `Connection` in the `Database` class, but because the constructor of `Connection` has arguments, you must set how to instanciate `Connection` beforehand (as seen before), and next use the `@inject` metadata:

```haxe
Container.setSingleton(Connection, function():Connection
{
    return new Connection("my_database", "127.0.0.1", 3306, "my password");
});

class Database
{
    @inject
    public var connection:Connection;

    public function new() {}

    public function query(sqlQuery:String)
    {
        // Code...
    }
}

var database = new Database();
// Or:
var database = Container.get(Database);
database.connection.databaseName == "my_database"; // returns true
```

Actually, to achieve this, Sugar adds a default value to the attribute thanks to macro system.

```haxe
class Database
{
    @inject
    public var connection:Connection;

    public function new() {}

    public function query(sqlQuery:String)
    {
        // Code...
    }
}
```

Is converted into this:

```haxe
class Database
{
    public var connection:Connection = sugar.Container.get(Connection);

    public function new() {}

    public function query(sqlQuery:String)
    {
        // Code...
    }
}
```

### Method arguments injection

You can also use the `@inject` metadata on function arguments (as well on constructor arguments). Instead of doing:

```haxe
import sugar.Container;

class A
{
    public var message = "I'm the class A!";

    public function new() {}
}

class C
{
    public function new() {}

    public function displayMessage(a:A):Void
    {
        trace(a.message);
    }
}

var c = Container.get(C);
c.displayMessage(Container.get(A)); // Outputs: I'm the class A!
```

You can do:

```haxe
import sugar.Container;

class A
{
    public var message = "I'm the class A!";

    public function new() {}
}

class C
{
    public function new() {}

    public function displayMessage(@inject a:A):Void
    {
        trace(a.message);
    }
}

var c = Container.get(C);
c.displayMessage(); // Outputs: I'm the class A!
```

The "injected" arguments disappear of the argument list: you don't have to provide them. You can also use it on static methods, and with others "non-injected" arguments:

```haxe
import sugar.Container;

class A
{
    public var message = "I'm the class A!";

    public function new() {}
}

class C
{
    public function new() {}

    public static function displayMessage(@inject a:A, message:String):Void
    {
        trace(a.message + " " + message);
    }
}

C.displayMessage("Hello!"); // Outputs: I'm the class A! Hello!
```

You can put injected arguments at the beginning, at the end, or anywhere in the mess, it doesn't matter. In deed, to achieve this, Sugar removes them from the argument list and instanciates them in the method body.

```haxe
class C
{
    public function new() {}

    public static function displayMessage(@inject a:A, message:String):Void
    {
        trace(a.message + " " + message);
    }
}
```

Is converted into this:

```haxe
class C
{
    public function new() {}

    public static function displayMessage(message:String):Void
    {
        var a:A = sugar.Container.get(A);
        trace(a.message + " " + message);
    }
}
```

## Interface implementations

You can also inject interfaces. If there are multiple implementations of an interface, you can next change the implementation easily:

```haxe
import sugar.Container;

interface CacheDriver
{
    public function set(key:String, value:Dynamic):Void;
    public function get(key:String):Dynamic;
}

class RedisCacheDriver implements CacheDriver
{
    public function new(host:String, port:Int)
    {
        // Code...
    }

    public function set(key:String, value:Dynamic):Void
    {
        // Code...
    }

    public function get(key:String):Dynamic
    {
        // Code...
    }
}

class Database
{
    @inject
    private var cache:CacheDriver;

    public function new() {}
}

Container.setSingleton(CacheDriver, function():CacheDriver
{
    return Container.get(RedisCacheDriver);
});

var database = new Database(); // The RedisCacheDriver is used.
// Or:
var database = Container.get(Database); // The RedisCacheDriver is used.
```

It's very useful for modular systems. You define interfaces and implementations, you inject dependencies with interface types in your classes, and then you can easily change the implementation by changing the `Container.setSingleton` call.

[Come back to the Index](../README.md)