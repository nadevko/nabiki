final: prev:
let
  inherit (builtins) isFunction isAttrs;
  inherit (prev.trivial) warnIf;
  inherit (prev.customisation) overrideDerivation;

  inherit (final.mixins) toMixin;
  inherit (final.trivial) mirrorArgsFrom compose;
  inherit (final.debug) attrPos;
  inherit (final.lists) subtractStrings;
in
rec {
  makeOverridableWith =
    wrapper: fn:
    let
      overridable = wrapper fn;
      functor = makeOverridableWith wrapper;
    in
    if isAttrs fn then
      let
        base = fn // overridable;
      in
      if fn ? override then base // { override = compose functor fn.override; } else base
    else
      overridable;

  makeOverridable = makeOverridableWith (compose makeFastOverridable makeDynamicOverridable);

  makeFastOverridable =
    fn:
    let
      mirror = mirrorArgsFrom fn;

      recurse =
        callee: args:
        let
          result = callee args;

          overrideArgs = mirror (
            nextArgs:
            let
              applied = args // (if isFunction nextArgs then nextArgs args else nextArgs);
            in
            if applied == args then overrideArgs else recurse callee applied
          );
        in
        if isAttrs result then
          result // { override = overrideArgs; }
        else if isFunction result then
          mirrorArgsFrom result result // { override = overrideArgs; }
        else
          result;
    in
    mirror (args: recurse fn args);

  makeDynamicOverridable =
    fn:
    let
      mirror = mirrorArgsFrom fn;

      decorate =
        args:
        let
          result = fn args;

          overrideResult = g: makeFastOverridable (mirror (a: g (fn a))) args;

          builtinsNames = [
            "override"
            "overrideDerivation"
          ]
          ++ (if result ? overrideAttrs then [ "overrideAttrs" ] else [ ]);

          extraNames =
            let
              fromResult = if isAttrs result && result ? __overriders then result.__overriders else [ ];
              fromFn = if isAttrs fn && fn ? __overriders then fn.__overriders else [ ];
            in
            subtractStrings (fromResult ++ fromFn) (builtinsNames ++ [ "__overriders" ]);

          newOverriders = builtinsNames ++ extraNames;
        in
        if isAttrs result then
          result
          // {
            override = mirror (newArgs: overrideResult (x: x.override newArgs));
            overrideDerivation = fdrv: overrideResult (x: overrideDerivation x fdrv);
            ${if result ? overrideAttrs then "overrideAttrs" else null} =
              fdrv: overrideResult (x: x.overrideAttrs fdrv);
            __overriders = newOverriders;
          }
        else if isFunction result then
          mirrorArgsFrom result result
          // {
            override = mirror (newArgs: overrideResult (x: x.override newArgs));
            __overriders = [ "override" ];
          }
        else
          result;
    in
    mirror decorate;

  makeDerivationExtensible =
    makeDerivation: rattrs:
    let
      args = rattrs (args // { inherit finalPackage overrideAttrs; });

      overrideAttrs =
        mayBeMixin:
        let
          mixin = toMixin mayBeMixin;
          mix' =
            oldRattrs: final:
            let
              prevValues = oldRattrs final;
              overlay = mixin final prevValues;

              warnForBadVersionOverride = (
                prevValues ? src
                && overlay ? version
                && prevValues ? version
                && !(overlay ? src)
                && !(overlay.__intentionallyOverridingVersion or false)
              );

              name = args.name or "${args.pname or "<unknown>"}-${args.version or "<unknown>"}";
              pos = attrPos "version" overlay;
            in
            warnIf warnForBadVersionOverride ''
              ${name} was overridden with `version` but not `src` at ${pos}.
              (To silence this, set `__intentionallyOverridingVersion = true`.)
            '' (prevValues // (removeAttrs overlay [ "__intentionallyOverridingVersion" ]));
        in
        makeDerivationExtensible makeDerivation (mix' rattrs);

      finalPackage = makeDerivation (
        removeAttrs args [
          "overrideAttrs"
          "finalPackage"
        ]
      );
    in
    makeOverridable (finalPackage // { inherit overrideAttrs; });
}
