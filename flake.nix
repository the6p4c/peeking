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
            (writeShellScriptBin "archive-org-process" ''
              path=$1
              if [ -z "$path" ]; then
                echo "usage: $0 <path>"
                exit 1
              fi

              jq '
                def from_values($keys):
                  [keys, .]
                    | transpose
                    | map({ key: .[0], value: .[1] })
                    | from_entries;

                .[0] as $keys
                  | .[1:] as $values
                  | $values
                  | map(from_values($keys))
              ' "$path"
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
