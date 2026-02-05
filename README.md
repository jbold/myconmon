# myconmon

Personal Continuous Monitoring for your laptop. Security-first observability with risk-based alerting.

## What it does

- **Drift detection**: Runs goss to verify your system matches known-good state
- **Risk scoring**: Fibonacci RPN (Severity² × Occurrence × Detectability)
- **Alerts**: Desktop notifications for high-priority findings

## Quick Start

```bash
# Run a drift check now
./myconmon check

# Install systemd timers (boot + weekly)
./myconmon install
```

## Status

v0.1 - MVP (shell + Python, Rust rewrite planned)

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Collection │────▶│  Decision   │────▶│  Response   │
│   (goss)    │     │   (RPN)     │     │  (notify)   │
└─────────────┘     └─────────────┘     └─────────────┘
```

## License

MIT
