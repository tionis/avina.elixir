#!/bin/bash
mix deps.get
MIX_ENV=prod mix release
rsync -a _build/prod/rel/glyph rsync.net:artifacts/
