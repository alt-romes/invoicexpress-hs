#!/usr/bin/env bash
# Regenerate the InvoiceXpress bindings from the published OpenAPI spec.
# Requires `openapi3-code-generator-exe` on PATH, built with GHC <= 9.6 and aeson < 2.2:
# the Template Haskell names it emits must match the modules its generated imports alias.
#   nix-shell -p haskell.compiler.ghc96 --run "cabal install openapi3-code-generator -w ghc --constraint='aeson<2.2'"
set -euo pipefail
cd "$(dirname "$0")"

curl -sfL 'https://docs.invoicexpress.com/_bundle/index.yaml?download' -o spec/invoicexpress-3.1.yaml

# The generator only understands OpenAPI 3.0: rewrite `type: [T, "null"]` as `type: T, nullable: true`.
nix-shell -p yq-go --run "yq '
  .openapi = \"3.0.3\" |
  (.. | select(tag == \"!!map\" and (.type | tag) == \"!!seq\")) |= (.nullable = true | .type = (.type - [\"null\"])[0])
' spec/invoicexpress-3.1.yaml > spec/invoicexpress.yaml"

# Note: the generator wipes `outputDir` (see openapi-configuration.yml).
openapi3-code-generator-exe --configuration openapi-configuration.yml --log-level WARN
