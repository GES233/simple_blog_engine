# Blog

*Contemplate the marvel that is existence, and rejoice that you are able to do so.*

Only for individual.

90% above compat with Hexo.

## Prerequisite

- Pandoc
  - Pandoc-crossref
- Graphviz
- Lilypond
- Tailwind Standalone

## How to use

~~Really?~~

### Configure

Blog entrance

Content entrance

### Format

Write blog like:

```markdown
---
date:
title:
tags: []
category:
- []
---
Your content.
```

### AIO

```
$env:MIX_ENV='prod'; mix tailwind default --input=apps/ges233/assets/css/app.css --minify --output=priv/generated/assets/css/app.css; mix g.gen; mix g.deploy
```
