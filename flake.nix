{
  description = "An experimental sandboxing tool for linux apps";

  inputs.nixpkgs.url = github:NixOS/nixpkgs;

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.default =
      with import nixpkgs { system = "x86_64-linux"; };
      nimPackages.buildNimPackage {
        name = "bwbox";
        src = self;
      };
  };
}
