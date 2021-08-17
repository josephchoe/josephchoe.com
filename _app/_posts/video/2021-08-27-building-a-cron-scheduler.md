---
title: Building a Cron Scheduler
date: 2021-08-27 08:00:00 -0600
author: joseph
youtube_video_id: 699CUZaCbIc
excerpt: Using the Actor model of concurrent computation, I build a cron scheduler in Ruby intended to be a single lightweight process within a larger distributed system, its only purpose to schedule work that other processes on other larger server instances complete.
---

## Description

Using the Actor model of concurrent computation, I build a cron scheduler in Ruby intended to be a single lightweight process within a larger distributed system, its only purpose to schedule work that other processes on other larger server instances complete.

### Dependencies

- `ntl-actor`
- `parse-cron`
- Other Eventide Project packages

### Links

- [Rethinking Cron](https://adam.herokuapp.com/past/2010/4/13/rethinking_cron/) by Adam Wiggins

Discuss: [https://reddit.com/r/josephchoe](https://reddit.com/r/josephchoe)

Code: [https://github.com/bluepuppetcompany](https://github.com/bluepuppetcompany)
