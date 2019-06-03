package tests;

import utest.Test;

class Fallback extends Test
{
    public function specFallback():Void
    {
        (@fallback ["a", "b"]) == "a";
        (@fallback [null, 3]) == 3;
        (@fallback [null, null]) == null;
        (@fallback [4, 3, 2]) == 4;
        (@fallback [null, false, true]) == false;
        (@fallback [null, null, true]) == true;
    }
}