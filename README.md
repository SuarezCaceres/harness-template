# Harness template

Plantilla de monorepo para trabajar con agentes de IA (Claude Code y Antigravity CLI), sin atarse a ningún stack concreto.

Se basa en lo que publican OpenAI (harness engineering con Codex), Anthropic (harnesses para agentes de larga duración), Boris Cherny (creador de Claude Code), Birgitta Böckeler (Thoughtworks) y HumanLayer:

- **`AGENTS.md` corto como índice.** El detalle vive en `docs/` y se lee solo cuando hace falta (divulgación progresiva).
- **Guías:** reglas, stack, specs y skills, que orientan al agente **antes** de actuar.
- **Sensores:** lint, tipos, pruebas y hooks de git, que detectan errores **después** de actuar.
- **Memoria entre sesiones:** `PROGRESS.md`, `TASKS.md`, `features.json` y el historial de git.
- **Evaluador separado:** la skill `revisor` revisa el trabajo contra la spec.
- **Ciclo de aprendizaje:** cada error corregido se convierte en una regla.

## Estructura

```
AGENTS.md                     ← índice único (lo leen Claude Code y Antigravity)
init.sh                       ← prepara el entorno igual en cada sesión
.env.example
apps/
  web/                        ← frontend   (AGENTS.md local con punteros)
  api/                        ← backend    (AGENTS.md local con punteros)
packages/                     ← código compartido
tests/
  integration/
  e2e/
scripts/
  check.sh                    ← sensor principal: lint + tipos + pruebas
.githooks/
  pre-commit                  ← ejecuta check.sh --rapido (sirve para cualquier agente)
  pre-push                    ← bloquea push a main
.agents/skills/               ← skills (copia real; Antigravity las lee aquí)
  init-stack/
  spec-plan-code/
  frontend-proyecto/
  backend-proyecto/
  pruebas-proyecto/
  revisor/
.claude/
  skills -> ../.agents/skills ← enlace para que Claude Code vea las mismas skills
  settings.json               ← permisos y hook de seguridad de Claude Code
  hooks/guard.sh
docs/
  project/   PROJECT.md, ARCHITECTURE.md
  stack/     frontend.md, backend.md          ← cambia en cada proyecto
  rules/     general, frontend, backend, testing, security
  references/frontend|backend|testing/        ← tus materiales de consulta
  specs/_plantilla/  spec.md, plan.md
  decisions/ ADRs
  features.json                               ← lista de funcionalidades y criterios
  TASKS.md
  PROGRESS.md
```

## Cómo usarla en un proyecto nuevo

1. Crea el repo a partir de esta plantilla ("Use this template" en GitHub) y clónalo.
2. Ejecuta `./init.sh`. Activa los hooks de git y comprueba el enlace de skills.
3. Abre tu agente y pídele: **"usa la skill init-stack"**. Te preguntará el stack y rellenará `docs/stack/`, los comandos de `AGENTS.md`, `scripts/check.sh` e `init.sh`.
4. Rellena `docs/project/PROJECT.md` (o pídele al agente que te entreviste para rellenarlo).
5. Instala las skills de terceros que necesites para ese stack:
   ```bash
   npx skills add <usuario/repo> -a claude-code -a antigravity
   ```
   Léelas antes de usarlas y menciónalas en la skill orquestadora que corresponda (`frontend-proyecto`, `backend-proyecto` o `pruebas-proyecto`).
6. Para la primera funcionalidad: **"usa spec-plan-code para <funcionalidad>"**.

## Notas

- **Windows:** el enlace `.claude/skills` necesita el modo desarrollador activado y `git config core.symlinks true` **antes** de clonar. Si no funciona, `init.sh` te avisa. Como alternativa, copia la carpeta `.agents/skills` a `.claude/skills`.
- **No crees `CLAUDE.md` ni `GEMINI.md`.** Claude Code solo lee `AGENTS.md` si no existe ningún `CLAUDE.md` (tampoco en carpetas superiores, como tu home).
- **Hooks:** los de `.githooks/` funcionan con cualquier agente y también contigo. El de `.claude/` es una protección extra solo para Claude Code.
- **Mantenimiento:** si `AGENTS.md` supera las ~120 líneas, mueve contenido a `docs/` o a una skill.
