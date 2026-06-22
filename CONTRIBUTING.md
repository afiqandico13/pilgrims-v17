# Contributing to PILGRIMS

Thanks for your interest in contributing to PILGRIMS v17.0 — Ultimate Security
Framework! This document explains how to get involved.

## Ground Rules

1. **Authorization first** — Any new scanning/testing capability must include
   clear notes on the legal/ethical context. Tools for attacking systems are
   welcome, but docs MUST emphasize authorized use only.

2. **Privacy first** — No telemetry, no analytics, no phone-home. New features
   that require network calls must be opt-in and clearly flagged.

3. **Modular architecture** — New modules go in `modules/module-<name>/` with
   the standard structure:
   ```
   modules/module-<name>/
   ├── pilgrims-<name>.sh    # main module script
   ├── plugins/              # optional: per-check scripts
   ├── reports/              # runtime outputs (gitignored)
   └── logs/                 # runtime logs (gitignored)
   ```

4. **Shellcheck clean** — All new/modified `.sh` files must pass
   `shellcheck -S error` with no errors. Warnings are tolerated but should be
   justified with `# shellcheck disable=SC...` comments.

5. **Bash 4+ compatibility** — Use bash features available in Ubuntu 20.04+
   and WSL2 default. Avoid bash 5+ only features unless behind a version check.

## Development Workflow

```bash
# Fork & clone
git clone https://github.com/<your-username>/pilgrims-v17.git
cd pilgrims-v17

# Create feature branch
git checkout -b feat/<module-name>

# Install shellcheck (Ubuntu/Debian)
sudo apt install shellcheck

# Validate your changes
shellcheck -S error modules/module-<name>/pilgrims-<name>.sh
bash -n modules/module-<name>/pilgrims-<name>.sh

# Smoke test the framework
./pilgrims.sh --help
./pilgrims.sh --modules
```

## Pull Request Process

1. Open an issue first describing the module/feature you want to add
2. Fork the repo and create a feature branch (`feat/...`, `fix/...`)
3. Run shellcheck + bash -n on your changes
4. Update relevant docs in `MODULES.md`, `FEATURES.md`, or `USER_GUIDE.md`
5. Submit a PR referencing the original issue
6. Wait for review (1-2 weeks typical)

## Reporting Security Issues

If you discover a security issue in PILGRIMS itself (not in a target system):

- Email: afiqandico13@gmail.com (subject prefix: `[PILGRIMS-SEC]`)
- Do NOT open a public issue
- Allow up to 90 days for coordinated disclosure

## Code of Conduct

- Be respectful and constructive
- Focus on the work, not the person
- Credit others' work (PRs, blog posts, prior art)
- Remember: security tools are dual-use. Default to defensive framing in docs.

---

*PILGRIMS v17.0 — by Afiq Andico Pangimpian, Bali, Indonesia*
