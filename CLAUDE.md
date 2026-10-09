# Databricks-Demo

Beispieldaten und Storyline für eine Databricks-Demo mit Genie. Die Storyline steht in `Context.md`.

## Git-Arbeitsweise

- `dev` ist der Arbeitsbranch. Florian bleibt lokal auf `dev` ausgecheckt.
- Ein fertig implementiertes Feature wird immer nach `dev` gemergt und nach `origin/dev` gepusht.
- Wenn Claude isoliert in einem Worktree arbeitet, ist dessen Branch nur temporär: nach dem Merge in `dev` wird er nicht weiterverwendet und nicht als eigener Branch auf GitHub gepusht.
- Nicht auf `master` pushen.
- Die `.claude`-Ordner werden nicht eingecheckt (siehe `.gitignore`).
