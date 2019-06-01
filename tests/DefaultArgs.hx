package tests;

import utest.Test;

class DefaultArgs extends Test
{
    public static function test1(param1:String, param2:Array<Int> = []):String
    {
        //trace(param2);
        return param1 + param2.join("");
    }

    public static function test2(param1:String, param2 = test1(param1, [0, 1, 2])):String
    {
        return param1 + param2;
    }

    public function specTest1():Void
    {
        test1("Hello") == "Hello";
        test1("Hello", [1, 3, 4]) == "Hello134";
    }

    public function specTest2():Void
    {
        test2("Hello", "how are you?") == "Hellohow are you?";
        test2("Hello") == "HelloHello012";
    }
}