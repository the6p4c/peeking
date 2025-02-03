{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in with pkgs; {
        devShells.default = mkShell {
          packages = [
            httpie
            (writeShellScriptBin "archive-org" ''
              domain=$1
              if [ -z "$domain" ]; then
                echo "usage: $0 <domain>"
                exit 1
              fi

              # https://archive.org/developers/wayback-cdx-server.html
              http -d 'https://web.archive.org/cdx/search/cdx' \
                output==json \
                matchType==domain \
                "url==$domain"
            '')
            (writeShellScriptBin "archive-org-urls" ''
              path=$1
              if [ -z "$path" ]; then
                echo "usage: $0 <path>"
                exit 1
              fi

              jq -r '(.[0] | index("original")) as $index_original | .[1:][] | .[$index_original]' "$path" \
                | sort \
                | uniq
            '')
            (writeShellScriptBin "crt-sh" ''
              domain=$1
              if [ -z "$domain" ]; then
                echo "usage: $0 <domain>"
                exit 1
              fi

              http -d 'https://crt.sh' \
                output==json \
                "q==$domain"
            '')
            (writeShellScriptBin "crt-sh-domains" ''
              path=$1
              if [ -z "$path" ]; then
                echo "usage: $0 <path>"
                exit 1
              fi

              jq -r 'map([.common_name, .name_value | split("\n")] | flatten) | flatten[]' "$path" \
                | sort \
                | uniq
            '')
          ];
        };
      });
}
