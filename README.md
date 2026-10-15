# CMPStack Consent Banner — Google Tag Manager template

The Community Template Gallery entry for the CMPStack consent banner. One tag, fired on
**Consent Initialization – All Pages**, that:

- sets Google Consent Mode v2 to *denied* inside the container before any other tag
  reads it, and again via the banner's own `gtag('consent', …)` calls outside it;
- applies a returning visitor's stored decision in that same step, read from the
  tag's own `cmpstack_consent` cookie, so tags that require consent fire on every
  page after the visitor allowed them;
- loads the CMPStack tag, which holds third-party scripts back until the visitor
  allows their category, records the decision, and updates Consent Mode.

Permissions: injects one script from `https://cdn.cmpstack.io/`, writes the four
Consent Mode v2 types, and reads one cookie, `cmpstack_consent`. Nothing else.

One limit, stated in the template: Tag Manager templates cannot read
`navigator.globalPrivacyControl`. A visitor who accepted and later turned Global
Privacy Control on has their acceptance applied on their next page until the tag
loads and records the opt-out; every page after that is denied from the start.

Configure it with the **Site ID** from *Domains → Install tag* in your CMPStack panel.
Full instructions: https://cmpstack.io/docs/install/gtm

## Source

The template is maintained in the CMPStack script repository under
`platforms/gtm/template.tpl`; this repository is the gallery's copy, produced by
`release.sh` there. Please open issues and pull requests against the source.

## Licence

Apache License 2.0 — see `LICENSE`.
