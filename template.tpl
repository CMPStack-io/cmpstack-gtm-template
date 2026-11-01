___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.

___INFO___

{
  "type": "TAG",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "CMPStack Consent Banner",
  "categories": ["UTILITY", "ANALYTICS"],
  "brand": {
    "id": "brand_dummy",
    "displayName": "CMPStack",
    "thumbnail": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAABDElEQVR42u3bURKCMAxF0SzFTbn/X3ehC3AQaknea3M746e0OQiWkEQMjtfz8Xb+xN3DPeA0kNUDn4LYLfghhF2Dv4Swe/A/EboEf4jQGqBb8F8IAADQGGD0SyuMIQQAAPgfwOl6BgAAAAAAAAAA8gEcEWbWE4pJXYIHYAbAAeGO+QFwWIRy3nBajGI+ABwXVTkPAM6Lqzh+rLDIzOMCsMJPNfPSAsD9bp19YwXA+T+7Ym8RrtvWqo0VAI4PL5UPVwC4JTCqH61Ly2POglNklwBwSWSqcosAOKSzlel1WY3gbHGTtFZwFwB5pajF2QdAXCusfLts0TMgP/t0jNA0RdscjZO0ztI83bd9/gMoNlQ7XZ3GwQAAAABJRU5ErkJggg=="
  },
  "description": "Loads the CMPStack consent banner and sets Google Consent Mode v2 signals denied-first, before any other tag fires, with optional defaults per region. Fire this on Consent Initialization - All Pages.",
  "containerContexts": ["WEB"]
}

___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "siteId",
    "displayName": "Site ID",
    "simpleValueType": true,
    "help": "From Domains → Install tag in your CMPStack panel. It is the domain's id, not its hostname.",
    "valueValidators": [
      {"type": "NON_EMPTY"},
      {
        "type": "REGEX",
        "args": ["^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"],
        "errorMessage": "That does not look like a site ID. Copy it from Domains → Install tag."
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "apiUrl",
    "displayName": "API URL",
    "simpleValueType": true,
    "defaultValue": "https://api.cmpstack.io",
    "help": "Leave as-is unless you are on a dedicated instance."
  },
  {
    "type": "PARAM_TABLE",
    "name": "regionalDefaults",
    "displayName": "Regional defaults",
    "help": "Optional. Every region not listed here starts with all four signals denied. Add a row to start a region differently, for example granted in a country where your banner's Targeting is set to No banner. The visitor's choice replaces these defaults as soon as they make one.",
    "paramTableColumns": [
      {
        "param": {
          "type": "TEXT",
          "name": "region",
          "displayName": "Regions (ISO 3166-2, comma separated, e.g. US, US-CA, CA)",
          "simpleValueType": true,
          "valueValidators": [
            {"type": "NON_EMPTY"},
            {
              "type": "REGEX",
              "args": ["^\\s*[A-Za-z]{2}(-[A-Za-z0-9]{1,3})?(\\s*,\\s*[A-Za-z]{2}(-[A-Za-z0-9]{1,3})?)*\\s*$"],
              "errorMessage": "Use ISO 3166-2 codes separated by commas, such as US, US-CA or GB."
            }
          ]
        },
        "isUnique": true
      },
      {
        "param": {
          "type": "SELECT",
          "name": "ad_storage",
          "displayName": "ad_storage",
          "macrosInSelect": false,
          "selectItems": [{"value": "denied", "displayValue": "Denied"}, {"value": "granted", "displayValue": "Granted"}],
          "simpleValueType": true,
          "defaultValue": "denied"
        },
        "isUnique": false
      },
      {
        "param": {
          "type": "SELECT",
          "name": "analytics_storage",
          "displayName": "analytics_storage",
          "macrosInSelect": false,
          "selectItems": [{"value": "denied", "displayValue": "Denied"}, {"value": "granted", "displayValue": "Granted"}],
          "simpleValueType": true,
          "defaultValue": "denied"
        },
        "isUnique": false
      },
      {
        "param": {
          "type": "SELECT",
          "name": "ad_user_data",
          "displayName": "ad_user_data",
          "macrosInSelect": false,
          "selectItems": [{"value": "denied", "displayValue": "Denied"}, {"value": "granted", "displayValue": "Granted"}],
          "simpleValueType": true,
          "defaultValue": "denied"
        },
        "isUnique": false
      },
      {
        "param": {
          "type": "SELECT",
          "name": "ad_personalization",
          "displayName": "ad_personalization",
          "macrosInSelect": false,
          "selectItems": [{"value": "denied", "displayValue": "Denied"}, {"value": "granted", "displayValue": "Granted"}],
          "simpleValueType": true,
          "defaultValue": "denied"
        },
        "isUnique": false
      }
    ]
  }
]

___SANDBOXED_JS_FOR_WEB_TEMPLATE___

// CMPStack consent banner.
//
// Fire this tag on the "Consent Initialization - All Pages" trigger. That trigger is
// the only one GTM guarantees runs before every other tag in the container, which is
// exactly the guarantee this tag needs: Consent Mode has to be set to denied BEFORE a
// Google tag reads it, and blocking has to be armed before a pixel is injected.
//
// GTM's sandbox has no DOM access, so the script is loaded with injectScript rather
// than by writing a <script> element.

const injectScript = require('injectScript');
const gtagSet = require('gtagSet');
const setDefaultConsentState = require('setDefaultConsentState');
const updateConsentState = require('updateConsentState');
const getCookieValues = require('getCookieValues');
const getTimestampMillis = require('getTimestampMillis');
const getType = require('getType');
const JSON = require('JSON');
const encodeUriComponent = require('encodeUriComponent');

// Denied-first, here as well as in the script itself.
//
// This covers every tag INSIDE the container. A gtag.js loaded directly in the page,
// outside GTM, reads `gtag('consent','default')` instead — that is what the inline
// denied-first snippet in the install instructions is for, and it is the only thing
// that keeps such a tag closed if this template's script cannot be fetched.
//
// Not redundant: GTM's own consent API is what gates tags inside this container, and
// it is a different mechanism from the `gtag('consent', ...)` call the banner makes
// for tags outside it. A tag in this container that declares a consent requirement
// checks THIS state, so without it GTM would let those tags fire while the banner
// still believed everything was denied.
//
// CMPStack's Google tag Developer ID comes first, so Google attributes this
// container's consent signals to us from the very first command. The tag's script
// sets it too (src/gcm.ts), but only once injectScript has fetched it.
gtagSet({'developer_id.dZmZiYj': true});

setDefaultConsentState({
  ad_storage: 'denied',
  ad_user_data: 'denied',
  ad_personalization: 'denied',
  analytics_storage: 'denied',
  wait_for_update: 500
});

// Regional defaults, from the tag's "Regional defaults" table.
//
// A default that names a region wins over the one above for visitors in it, so a
// row only ever changes where the site owner listed it; everywhere else stays
// denied-first. A row whose regions are blank is skipped rather than sent: without
// `region` it would be a second global default, and could grant what the one above
// denied for every visitor.
const signal = function (v) { return v === 'granted' ? 'granted' : 'denied'; };
const rows = getType(data.regionalDefaults) === 'array' ? data.regionalDefaults : [];
for (let i = 0; i < rows.length; i++) {
  const row = rows[i];
  const parts = (row.region || '').split(',');
  const regions = [];
  for (let j = 0; j < parts.length; j++) {
    const code = parts[j].trim().toUpperCase();
    if (code) regions.push(code);
  }
  if (regions.length) {
    setDefaultConsentState({
      ad_storage: signal(row.ad_storage),
      ad_user_data: signal(row.ad_user_data),
      ad_personalization: signal(row.ad_personalization),
      analytics_storage: signal(row.analytics_storage),
      region: regions,
      wait_for_update: 500
    });
  }
}

// A returning visitor's decision, applied here and now.
//
// The tag's own script applies it too, but only once injectScript has fetched it —
// and by then Tag Manager has already started the page's other tags. A Google tag
// waits (wait_for_update above); a tag set to "Require additional consent" does not:
// it saw "denied", was skipped, and is never reconsidered. Measured on a real
// container: a visitor who had accepted never got such a tag on any later page.
// Setting the stored state in this same Consent Initialization step is what every
// established consent template does, and what makes those tags fire.
//
// The checks are the tag's own (src/consent.ts and the returning-visitor path in
// src/index.ts), so the two never disagree about whether a record counts:
//  - version 1, a numeric timestamp, `necessary` exactly true — anything else is a
//    malformed cookie, which the tag re-asks about;
//  - within its own lifetime (`e` months, 12 for a record that predates it);
//  - not `n`: consent implied while its notice was never shown, so not yet told.
//
// One check of the tag's it cannot make: Global Privacy Control. Tag Manager refuses
// a template that reads any built-in browser global, `navigator` included, so the
// signal is invisible from here. The case it leaves is narrow: a US visitor who
// accepted, then switched the signal on. On their next page this applies the old
// acceptance; the tag then loads, records the opt-out and updates everything to
// denied, and their record carries the signal from then on (`g`), so every later
// page is denied from the start. The exposure is that one page view. Staying
// denied for every returning US visitor instead would make every page after the
// first skip the tags of all the visitors who did accept.
const MONTH_MS = 2592000000;
const stored = (function () {
  const raw = getCookieValues('cmpstack_consent')[0];
  if (!raw) return null;
  const r = JSON.parse(raw);
  if (getType(r) !== 'object' || r.v !== 1 || getType(r.ts) !== 'number') return null;
  if (getType(r.state) !== 'object' || r.state.necessary !== true) return null;
  if (getTimestampMillis() - r.ts > (r.e || 12) * MONTH_MS) return null;
  if (r.n) return null;
  return r.state;
})();

if (stored) {
  const marketing = stored.marketing === true ? 'granted' : 'denied';
  updateConsentState({
    ad_storage: marketing,
    ad_user_data: marketing,
    ad_personalization: marketing,
    analytics_storage: stored.analytics === true ? 'granted' : 'denied'
  });
}

const api = data.apiUrl || 'https://api.cmpstack.io';
const url = 'https://cdn.cmpstack.io/cmpstack.js?site=' +
  encodeUriComponent(data.siteId) + '&api=' + encodeUriComponent(api);

injectScript(url, data.gtmOnSuccess, data.gtmOnFailure, 'cmpstack');

___WEB_PERMISSIONS___

[
  {
    "instance": {
      "key": {"publicId": "inject_script", "versionId": "1"},
      "param": [
        {
          "key": "urls",
          "value": {
            "type": 2,
            "listItem": [{"type": 1, "string": "https://cdn.cmpstack.io/*"}]
          }
        }
      ]
    },
    "clientAnnotations": {"isEditedByUser": true},
    "isRequired": true
  },
  {
    "instance": {
      "key": {"publicId": "access_consent", "versionId": "1"},
      "param": [
        {
          "key": "consentTypes",
          "value": {
            "type": 2,
            "listItem": [
              {"type": 3, "mapKey": [{"type": 1, "string": "consentType"}, {"type": 1, "string": "read"}, {"type": 1, "string": "write"}], "mapValue": [{"type": 1, "string": "ad_storage"}, {"type": 8, "boolean": false}, {"type": 8, "boolean": true}]},
              {"type": 3, "mapKey": [{"type": 1, "string": "consentType"}, {"type": 1, "string": "read"}, {"type": 1, "string": "write"}], "mapValue": [{"type": 1, "string": "ad_user_data"}, {"type": 8, "boolean": false}, {"type": 8, "boolean": true}]},
              {"type": 3, "mapKey": [{"type": 1, "string": "consentType"}, {"type": 1, "string": "read"}, {"type": 1, "string": "write"}], "mapValue": [{"type": 1, "string": "ad_personalization"}, {"type": 8, "boolean": false}, {"type": 8, "boolean": true}]},
              {"type": 3, "mapKey": [{"type": 1, "string": "consentType"}, {"type": 1, "string": "read"}, {"type": 1, "string": "write"}], "mapValue": [{"type": 1, "string": "analytics_storage"}, {"type": 8, "boolean": false}, {"type": 8, "boolean": true}]}
            ]
          }
        }
      ]
    },
    "clientAnnotations": {"isEditedByUser": true},
    "isRequired": true
  },
  {
    "instance": {
      "key": {"publicId": "write_data_layer", "versionId": "1"},
      "param": [
        {"key": "keyPatterns", "value": {"type": 2, "listItem": [{"type": 1, "string": "developer_id.dZmZiYj"}]}}
      ]
    },
    "clientAnnotations": {"isEditedByUser": true},
    "isRequired": true
  },
  {
    "instance": {
      "key": {"publicId": "get_cookies", "versionId": "1"},
      "param": [
        {"key": "cookieAccess", "value": {"type": 1, "string": "specific"}},
        {"key": "cookieNames", "value": {"type": 2, "listItem": [{"type": 1, "string": "cmpstack_consent"}]}}
      ]
    },
    "clientAnnotations": {"isEditedByUser": true},
    "isRequired": true
  }
]

___TESTS___

scenarios:
- name: sets every Consent Mode v2 signal to denied before loading
  code: |
    const mockData = {siteId: '00000000-0000-4000-8000-000000000000', apiUrl: 'https://api.cmpstack.io'};
    let defaults = null;
    mock('setDefaultConsentState', (state) => { defaults = state; });
    mock('injectScript', (url, onSuccess) => { onSuccess(); });

    runCode(mockData);

    assertThat(defaults.ad_storage).isEqualTo('denied');
    assertThat(defaults.ad_user_data).isEqualTo('denied');
    assertThat(defaults.ad_personalization).isEqualTo('denied');
    assertThat(defaults.analytics_storage).isEqualTo('denied');
    assertApi('gtmOnSuccess').wasCalled();

- name: sets the CMPStack developer id
  code: |
    const mockData = {siteId: '00000000-0000-4000-8000-000000000000'};
    mock('setDefaultConsentState', () => {});
    mock('injectScript', (url, onSuccess) => { onSuccess(); });

    runCode(mockData);

    assertApi('gtagSet').wasCalledWith({'developer_id.dZmZiYj': true});

- name: applies a regional default only to the regions it names
  code: |
    const mockData = {
      siteId: '00000000-0000-4000-8000-000000000000',
      regionalDefaults: [
        {region: 'us, US-CA ', ad_storage: 'granted', analytics_storage: 'granted', ad_user_data: 'denied', ad_personalization: 'denied'},
        {region: ' ', ad_storage: 'granted', analytics_storage: 'granted', ad_user_data: 'granted', ad_personalization: 'granted'}
      ]
    };
    const calls = [];
    mock('setDefaultConsentState', (state) => { calls.push(state); });
    mock('injectScript', (url, onSuccess) => { onSuccess(); });

    runCode(mockData);

    assertThat(calls.length).isEqualTo(2);
    assertThat(calls[0].ad_storage).isEqualTo('denied');
    assertThat(calls[0].region).isUndefined();
    assertThat(calls[1].region).isEqualTo(['US', 'US-CA']);
    assertThat(calls[1].ad_storage).isEqualTo('granted');
    assertThat(calls[1].analytics_storage).isEqualTo('granted');
    assertThat(calls[1].ad_user_data).isEqualTo('denied');
    assertThat(calls[1].wait_for_update).isEqualTo(500);

- name: passes the site id to the CDN
  code: |
    const mockData = {siteId: '11111111-2222-4333-8444-555555555555'};
    let loaded = '';
    mock('setDefaultConsentState', () => {});
    mock('injectScript', (url, onSuccess) => { loaded = url; onSuccess(); });

    runCode(mockData);

    assertThat(loaded).contains('11111111-2222-4333-8444-555555555555');
    assertThat(loaded).contains('cdn.cmpstack.io');

- name: applies a returning visitor's stored decision before any other tag
  code: |
    const mockData = {siteId: '00000000-0000-4000-8000-000000000000'};
    const JSON = require('JSON');
    const getTimestampMillis = require('getTimestampMillis');
    let updated = null;
    mock('setDefaultConsentState', () => {});
    mock('updateConsentState', (state) => { updated = state; });
    mock('getCookieValues', () => [JSON.stringify({v: 1, ts: getTimestampMillis(), e: 12, state: {necessary: true, analytics: true, marketing: false, preferences: false}})]);
    mock('injectScript', (url, onSuccess) => { onSuccess(); });

    runCode(mockData);

    assertThat(updated.analytics_storage).isEqualTo('granted');
    assertThat(updated.ad_storage).isEqualTo('denied');
    assertThat(updated.ad_user_data).isEqualTo('denied');

- name: leaves an expired, pending or malformed record denied
  code: |
    const mockData = {siteId: '00000000-0000-4000-8000-000000000000'};
    const JSON = require('JSON');
    const getTimestampMillis = require('getTimestampMillis');
    const granted = {necessary: true, analytics: true, marketing: true, preferences: true};
    const records = [
      JSON.stringify({v: 1, ts: getTimestampMillis() - 400 * 86400000, state: granted}),
      JSON.stringify({v: 1, ts: getTimestampMillis(), n: 1, state: granted}),
      JSON.stringify({v: 2, ts: getTimestampMillis(), state: granted}),
      JSON.stringify({v: 1, ts: getTimestampMillis(), state: {necessary: 'yes', analytics: true}}),
      'not json'
    ];
    let calls = 0;
    mock('setDefaultConsentState', () => {});
    mock('updateConsentState', () => { calls = calls + 1; });
    mock('injectScript', (url, onSuccess) => { onSuccess(); });
    for (let i = 0; i < records.length; i++) {
      const value = records[i];
      mock('getCookieValues', () => [value]);
      runCode(mockData);
    }

    assertThat(calls).isEqualTo(0);

- name: reports failure when the script cannot load
  code: |
    const mockData = {siteId: '00000000-0000-4000-8000-000000000000'};
    mock('setDefaultConsentState', () => {});
    mock('injectScript', (url, onSuccess, onFailure) => { onFailure(); });

    runCode(mockData);

    assertApi('gtmOnFailure').wasCalled();

___NOTES___

Created by the CMPStack team.

Submission checklist (the gallery is a review process, not an upload):
  1. Push this file to a public GitHub repo as `template.tpl` at the root.
  2. Add `metadata.yaml` with the gallery listing details.
  3. Submit at tagmanager.google.com/gallery — Google reviews the permissions
     requested against what the code actually does, which is why the permission
     block above is narrow: one CDN host, four consent types written, one data
     layer key (our Google tag Developer ID) written, and one cookie (our own
     consent record) read.
