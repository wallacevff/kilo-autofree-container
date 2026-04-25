# Agent Configuration

This document describes the agent architecture for the Kilo CLI system.

## Available Agent Types

### explore
Fast agent specialized for exploring codebases. Used for:
- Finding files by patterns
- Searching code for keywords
- Answering questions about the codebase

**Thoroughness levels:**
- `quick` - Basic searches
- `medium` - Moderate exploration
- `very thorough` - Comprehensive analysis

### general
General-purpose agent for:
- Researching complex questions
- Executing multi-step tasks
- Parallel work units

### code-reviewer
Specialized agent for reviewing code after implementation work. Criteria for activation:
- User initiated feature implementation, bug fix, or refactor
- Work is at least 90% complete
- Resulting diff is substantial enough for meaningful review

**Do NOT use for:**
- Reviewing external PR feedback
- CI/lint failure reactions
- Non-implementation work (research, docs, config)
- Trivial changes (typos, formatting)

## Usage Pattern

When task matches agent capabilities:
1. Load agent using `skill` tool
2. Pass detailed task description
3. Agent operates autonomously with tools
4. Returns structured results

## Architecture

Kilo agents are sub-processes with isolated context but access to same tools. They perform autonomous exploration, analysis, and code generation without blocking the main conversation thread.
