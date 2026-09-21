{pkgs}: {
  extension = import ../mk-npm-extension.nix {
    inherit pkgs;
    npmRoot = builtins.toString ./.;
    packageName = "pi-ask-user";
    # The upstream package ships an `ask-user` skill next to the extension.
    skills = ["skills"];
  };
}
