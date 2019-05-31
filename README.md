# Haxe Sugar

The `sugar` haxe library provide several tools and syntaxic sugar to improve your Haxe experience and make your life easier.

To use Sugar, install it using `haxelib install sugar` (or `lix install haxelib:sugar` if you use Lix). Then, you have to add a macro call into your hxml file:

```hxml
--macro sugar.Sugar.use("yourpackage")
```

Sugar will be used only in the files inside `yourpackage`. If you want to use it in multiple packages, you can simply use multiple macro calls.