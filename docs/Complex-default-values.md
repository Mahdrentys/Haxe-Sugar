# Complex default values

In haxe, function arguments can have default values, but they must be *constant* values: string, int, float, bool or null literals. Thanks to Sugar, you can now use complex values as argument default values: "new" statements, function calls, etc. Example:

```haxe
class Test
{
    // [] is not a constant value
    public static function arrayLength(arg:Array = []):Int
    {
        return arg.length;
    }

    // You can even use values of previous arguments (here arg2 default value depends on arg1 value):
    public static function test2(arg1:Array, arg2:Int = arrayLength(arg1))
    {
        // Some code...
    }

    // But you can only use values of previous arguments, not of following arguments.
    // For example, this doesn't work:
    public static function test3(arg2:Int = arrayLength(arg1), arg1:Array = [])
    {
        // Some code...
    }
}
```

To achieve this, Sugar simply converts this (thanks to the macro system):

```haxe
class Test
{
    public static function arrayLength(arg:Array = []):Int
    {
        return arg.length;
    }

    public static function test2(arg1:Array, arg2:Int = arrayLength(arg1))
    {
        // Some code...
    }
}
```

Into this:

```haxe
class Test
{
    public static function arrayLength(arg:Array = null):Int
    {
        if (arg == null)
        {
            arg = [];
        }

        return arg.length;
    }

    public static function test2(arg1:Array, arg2:Int = null)
    {
        if (arg2 == null)
        {
            arg2 = arrayLength(arg1);
        }

        // Some code...
    }
}
```