# Glowtail 🪲

**An AI-powered incident responder on AWS.** When something breaks, Glowtail catches the alarm, has Claude read the evidence, and emails you a plain-English summary of what went wrong and where to look first.

It catches trouble two ways: from **inside** (the code throws an error) and from **outside** (a Route 53 health check can't reach the app, the way a real user would notice).

## Why Glowtail?

When an app breaks at 3am, the first ten minutes are the same every time: find the alarm, dig through logs, figure out what actually happened. Glowtail does that part for you. It's the smoke alarm that also hands you the fire report.

Glowtail grabs the tail of your logs and makes it glow in your inbox.

## How it works

1. **Something breaks.** A test Lambda (the "patient") throws an error, or its `/health` URL starts returning 500.
2. **Two watchers notice.**
    - **From inside:** a CloudWatch alarm trips as soon as the patient logs an error.
    - **From outside:** a Route 53 health check pings the patient's URL from locations around the world. When it fails, a second CloudWatch alarm trips.
3. **EventBridge reacts.** One rule catches either alarm and wakes up the responder.
4. **The responder investigates.** It figures out which alarm fired, then gathers the evidence: the patient's latest error logs, and for a health check failure, the reason Route 53 gave.
5. **Claude explains.** Logs are scrubbed of secrets, then Claude summarizes what broke, the likely cause, and where to look first.
6. **You get the email.** Summary on top, raw evidence below, usually within a couple of minutes.

If Claude is ever unavailable, Glowtail still sends the raw evidence. The responder should never be the thing that breaks.

## Tech stack

| Area | Tools |
| --- | --- |
| Infrastructure as Code | Terraform (remote state in S3 with locking) |
| CI/CD | GitHub Actions with OIDC (no stored AWS keys) |
| Compute | AWS Lambda (with a Function URL for the patient) |
| Monitoring | Amazon CloudWatch (metrics, alarms, logs) |
| DNS & health checks | Amazon Route 53 health checks |
| Events | Amazon EventBridge |
| Notifications | Amazon SNS |
| AI | Claude on Amazon Bedrock |
| Security | Least-privilege IAM, log scrubbing before AI |

## Design decisions

- **Terraform state lives in S3, not on a laptop.** One source of truth, versioned, locked so two runs can't collide.
- **No stored AWS keys.** Locally I sign in with `aws login` (short-lived credentials), and GitHub Actions signs in with OIDC. Nothing permanent to leak.
- **Check from inside and outside.** Error alarms catch what the code knows went wrong. A Route 53 health check catches what users would actually experience, even when the code never logs an error.
- **Event-driven.** Nothing runs until something breaks, so it costs almost nothing when things are healthy.
- **One responder, many alarms.** A single EventBridge rule feeds one responder, which reads the alarm and decides what evidence to gather.
- **Least privilege.** Each piece can only touch what it needs. The responder can read one function's logs and publish to one topic.
- **Scrub before AI.** Logs can hold keys, tokens, and emails. Those get masked before anything is sent to Claude.
- **Fail safe.** If the AI step fails, you still get the raw evidence.

## Cost

Glowtail is built to run cheap. Almost everything is serverless and only runs when an alarm fires. The one exception is the Route 53 health check, which has a small monthly fee, so it gets destroyed with Terraform between demos. The rough cost per incident (including the Claude call) will be listed here once measured.

## What I learned

> Coming soon, after it's built.

## Author

**Jessica Paradise**

Cloud engineer in training · AWS Certified Solutions Architect – Associate · AWS Certified Developer – Associate

- Website: [jessicaparadise.com](https://jessicaparadise.com)
- GitHub: [@jessicaparadise](https://github.com/jessicaparadise)
