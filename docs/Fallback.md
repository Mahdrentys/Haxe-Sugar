# Fallback values

If you're used to do this in haxe:

```haxe
var variable = a;
if (variable == null) variable = b;
```

Or with a ternary operator:

```haxe
var variable = a != null ? a : b;
```

You can now replace it by:

```haxe
var variable = @fallback [a, b];
```

All you have to do is to use the `@fallback` metadata followed by an array declaration with the values you want to assign in preference order. If the first value is null, it will return the second value, but if the second value is also null, it will return the third value, but if the third value is also null, it will return the fourth value, etc.

It demonstrates its full power when having more than two values. For example with four values:

```haxe
var variable = a != null ? a : (b != null ? b : (c != null ? c : d));
```

Instead of this, you can now write this:

```haxe
var variable = @fallback [a, b, c, d];
```