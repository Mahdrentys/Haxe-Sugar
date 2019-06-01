package tests;

import utest.UTest;
import sugar.Sugar;

class Runner
{
    public static function main()
    {
        UTest.run(
        [
            new DI(),
            new DefaultArgs()
        ]);
    }
}