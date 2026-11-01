# Localization Guide

Implementation status: **321 UI strings in all 9 languages, RTL, localized content and server messages are implemented. All translations were machine-written by an AI and have not been reviewed by native speakers. Do not treat them as final.**

## Three kinds of text

| Kind | Example | Storage | Resolved by |
|---|---|---|---|
| App UI strings | "Add to cart" | ARB files in `shared_localization`, generated `AppLocalizations`; optional overrides in `translations` | Flutter |
| System strings from the server | Validation errors, notification text | `translations` with a stable key; `notification_template_translations` | API, from `Accept-Language` |
| Cafe content | Product names, banners | `*_translations` tables | API |

API errors return a stable `code` plus a localized `message`, so a client never parses text. IDs, transaction references and status values are never translated: clients map `status` to a label.

## Content fallback

`requested language -> cafe default -> any available`. A cafe's default-language translation is required at creation, enforced by the service. The API returns `resolvedLanguage`, so the UI can mark fallback text.

## Adding a language

1. Insert into `languages` (Super Admin UI). 2. Add the ARB file. 3. Rebuild the Flutter apps. No business logic changes. A language without an ARB falls back to English UI while still serving its cafe content.

## Seeded languages

`en, hi, mr, es, fr, de, ar (RTL), pt, ja`. Language codes are BCP 47. `languages.direction` drives layout. `flutter_localizations` covers all nine languages on the current Flutter version; a test loads each one.

## RTL

Use `Directionality`-aware widgets (`EdgeInsetsDirectional`, `AlignmentDirectional`). Widget tests render in `ar`, and the customer menu was checked in a real browser. Bidi isolation of numbers on receipts is not implemented.

## Formatting

Dates and numbers use `intl` with the user's locale. Money grouping uses the viewer's language plus the cafe's country, because English in India groups as 1,25,000. Times currently display in the viewer's device timezone, not the branch's. Business dates and peak hours do use the branch timezone. Receipts print in the language chosen at order time (`orders.language_code`), using snapshots in `order_items.name_translations`.

## Translation quality

Machine-translated system strings must be flagged `is_reviewed = 0` until a human reviews them. No Hindi, Marathi, Arabic or Japanese strings ship as "complete" without that review.
