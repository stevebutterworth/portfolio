---
title: "Placeholder Post One"
date: 2026-06-12
author: "Steve Butterworth"
tags: [Placeholder, Rails]
excerpt: "Placeholder post to exercise the blog index and post layout before real copy lands."
thumbnail: "projects/gsk-mvoc/cover.png"
cover: "projects/gsk-mvoc/cover.png"
---
<!-- thumbnail/cover are stand-ins reusing existing project media (projects/gsk-mvoc/cover.png)
     until dedicated post artwork is produced. -->

This is placeholder copy for the first post, written only to exercise the blog
index and the post page layout before real writing is dropped in. Nothing here
is meant to be read for content; it is here to check spacing, type, and the
rendering of the usual markdown building blocks.

## A placeholder heading

A short placeholder paragraph under the heading, so the post styling can be
checked with a heading followed by body text, not just body text on its own.

The list below stands in for the kind of scannable summary a real post might
use:

- First placeholder point
- Second placeholder point
- Third placeholder point

And a fenced code block, so syntax highlighting can be checked on a real post
page rather than only in isolation:

```ruby
# placeholder snippet, purely for layout purposes
Article.all.select { |post| post.tags.include?("Rails") }
```

That closes out the placeholder body.
