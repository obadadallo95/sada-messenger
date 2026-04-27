# Sada AI Skills Configuration

This directory contains AI skills and workflows for the Sada mesh messaging project.

## Structure

```
.windsurf/
├── skills/
│   ├── sada-mesh-expert/          # Custom skill for mesh networking
│   └── [1,397+ antigravity skills] # Cloned from antigravity-awesome-skills
├── workflows/
│   └── sada-chat-feature.md       # Workflow for chat feature development
├── skills.config.json             # Project skill configuration
└── README.md                      # This file
```

## Available Skills

### Custom Skills (for Sada)
| Skill | Description |
|-------|-------------|
| `sada-mesh-expert` | Mesh networking, E2E encryption, BLE/Wi-Fi Direct constraints |

### Recommended Antigravity Skills
| Category | Skills |
|----------|--------|
| **Android** | `android-jetpack-compose-expert`, `kotlin-coroutines-expert` |
| **Security** | `security`, `security-audit`, `backend-security-coder` |
| **Database** | `database-design`, `postgres-best-practices` |
| **Architecture** | `architecture-patterns`, `clean-code` |
| **Testing** | `testing-patterns`, `e2e-testing-patterns` |
| **UI/UX** | `ui-ux-designer`, `mobile-design`, `i18n-localization` |

## Usage

### Activate a Skill
```bash
# Using the skill router
.windsurf/skills/skill-router/skill-router.sh enable android-jetpack-compose-expert

# Or copy to .claude/skills/
cp -r .windsurf/skills/android-jetpack-compose-expert ~/.claude/skills/
```

### Use a Workflow
```
/sada-chat-feature
```
This triggers the chat feature development workflow with all constraints and best practices.

## Adding New Skills

1. Create a new directory in `.windsurf/skills/your-skill/`
2. Add `skill.md` with the skill definition
3. Update `skills.config.json` to include the new skill

## Notes

- Skills are **not** automatically loaded - activate them as needed
- The `sada-mesh-expert` skill is essential for understanding the custom mesh implementation
- Always review generated code for mesh networking constraints (battery, bandwidth, storage)
