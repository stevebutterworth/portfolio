---
title: "ShotView, The Open"
role: "Senior Rails engineer"
brand: "NTT DATA"
delivered_via: "LEX & Pulse Group"
year: 2022
period: "2014 - 2023"
order: 1
tech: [Rails, Kafka, WebSockets, PostgreSQL, "D3.js", "Three.js"]
cover: "projects/ntt-shotview/cover.png"
gallery:
  - "projects/ntt-shotview/1.png"
  - "projects/ntt-shotview/2.png"
  - "projects/ntt-shotview/3.png"
  - "projects/ntt-shotview/4.png"
  - "projects/ntt-shotview/5.png"
  - "projects/ntt-shotview/6.png"
videos:
  - "https://www.youtube.com/watch?v=ebKv9aPsotI"
  - "https://www.youtube.com/watch?v=NeCOzhro_x8"
quote: ""              # TODO: a line from LEX / Pulse Group / NTT DATA if you have one
quote_author: ""
---

Live 3D shot-tracing and data visualisation for The Open Championship, delivered
for NTT DATA through LEX and Pulse Group. Over nine seasons I built the Rails
systems that turned raw, high-frequency scoring and tracking feeds into the
ShotView experience on theopen.com and on the big screens around the course.

Every shot from every player had to appear on the leaderboard within seconds,
rendered as a 3D trace over the hole, alongside live scores, hole statistics and
player form. The hard part was never the picture, it was the plumbing behind it:
reconciling Kafka streams, WebSocket feeds, HTTP scoring posts and GPS or timing
data into one trustworthy state, under an immovable four-day deadline where a
stall in front of a global audience is not an option.

I used PostgreSQL staging tables, bulk loading and pre-computed rollups to keep
the public site fast while the raw feeds churned underneath, and Rails with
D3.js and Three.js to drive the shot tracking, the public website and the
large-format event displays. From creative concept to over a million daily
visits, live, on time, every year.
