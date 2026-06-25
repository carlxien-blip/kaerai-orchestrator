# How this compares: BMAD-METHOD and LangGraph

A neutral positioning note. orchestrator-oss is **not** an agent framework and **not** a graph
runtime. It's a thin, file-and-hook pattern for keeping truth coherent and a human un-bottlenecked
across many Claude Code projects. The comparisons below are to clarify scope, not to rank.

## BMAD-METHOD

- **What it is:** an agentic-development methodology with a cast of specialized agent personas
  (analyst, product manager, architect, scrum master, developer, QA, etc.) that hand structured
  documents down a pipeline, plus a planning phase and a story/sharding workflow.
- **Where it overlaps:** both value an explicit doer/reviewer split, objective acceptance, and
  durable documents over chat memory.
- **Where it differs:** BMAD organizes *roles and a workflow within building one product*.
  orchestrator-oss organizes *truth and dispatch across many independent projects*, with a single
  brain holding canonical state. BMAD is largely framework/agent-pack; this is a handful of shell
  hooks plus a methodology, and is Claude-Code-specific. You could run a BMAD-style role pipeline
  *inside* a single spoke here.

## LangGraph

- **What it is:** a library for building stateful, multi-actor agent applications as graphs —
  nodes, edges, shared state, checkpointing, cycles, human-in-the-loop interrupts. A runtime you
  write programs against.
- **Where it overlaps:** both care about durable state across steps, human-in-the-loop gates, and
  multi-actor coordination.
- **Where it differs:** LangGraph is code-first infrastructure for *one application's* control
  flow and state machine. orchestrator-oss is file-first and runs *between* projects and CLI
  sessions, with no graph to author — coordination is via canonical files, hooks, and a dispatch
  protocol, not a programmed state graph. If you were building a single complex agent application,
  LangGraph is the right layer; this pattern sits above whatever each project is built with.

## One-line summary

| | Scope | Form | State model |
|---|---|---|---|
| **orchestrator-oss** | across many projects + CLI sessions | files + Claude Code hooks + protocol | canonical files, read live, referenced not copied |
| **BMAD-METHOD** | within building one product | agent personas + workflow packs | structured docs handed down a pipeline |
| **LangGraph** | within one agent application | a code library / runtime | a programmed graph with checkpointed state |
