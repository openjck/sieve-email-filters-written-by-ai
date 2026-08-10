require [
  "include",
  "environment",
  "variables",
  "relational",
  "comparator-i;ascii-numeric",
  "spamtest",
  "fileinto",
  "imap4flags",
  "extlists"
];

# Generated: When using Proton Mail, do not run this script on spam messages.
if allof (
  environment :matches "vnd.proton.spam-threshold" "*",
  spamtest :value "ge" :comparator "i;ascii-numeric" "${1}"
) {
  return;
}

# This is the folder that matching messages should be moved to.
set "folder" "Filtered out by AI";

# ==========================================================
# Feedback-request scoring filter.
# Sieve has no arithmetic, so points are tallied by
# appending one "x" per point, then measuring string
# length. 1 point = 10 on a 0-100 scale.
# Threshold: 10 normally, 13 if penalty signals appear.
#
# Apostrophe note: real subjects use straight (') and curly
# (’) apostrophes interchangeably. Phrases containing an
# apostrophe are written as :matches wildcards with "*" in
# the apostrophe's place so both forms (and none) match.
# ==========================================================

# ---- Hard vetoes: never score these ----

# Reply-shaped vetoes are guarded by a bulk-mail marker check:
# survey platforms (Medallia, Zendesk CSAT) inject In-Reply-To /
# References to thread their asks into real conversations, but
# they also carry markers no human reply ever does. A message
# with any bulk marker does not get the reply vetoes.

# Genuine replies carry In-Reply-To and no bulk markers.
if allof (
  exists "in-reply-to",
  not anyof (
    exists "list-unsubscribe",
    exists "feedback-id",
    exists "x-feedback-id",
    header :contains "auto-submitted" "auto-",
    header :contains "precedence" [
      "bulk",
      "list",
      "junk"
    ]
  )
) {
  return;
}

# Reply/forward subject prefixes. :matches anchors to the whole
# subject, so a mid-subject "re:" cannot trigger this. Same
# bulk-marker guard: marketers fake "Re:" prefixes, humans
# forwarding mail carry no bulk markers.
if allof (
  header :matches "subject" [
    "re:*",
    "re :*",
    "fw:*",
    "fw :*",
    "fwd:*",
    "fwd :*"
  ],
  not anyof (
    exists "list-unsubscribe",
    exists "feedback-id",
    exists "x-feedback-id",
    header :contains "auto-submitted" "auto-",
    header :contains "precedence" [
      "bulk",
      "list",
      "junk"
    ]
  )
) {
  return;
}

# Mail from anyone in your Proton contacts is never scored.
if header :list "from" ":addrbook:personal" {
  return;
}

# Code review, workplace review, and application-status language.
if header :contains "subject" [
  "review requested",
  "requested changes",
  "changes requested",
  "code review",
  "pull request",
  "merge request",
  "performance review",
  "peer review",
  "under review",
  "being reviewed",
  "review your application"
] {
  return;
}

set "tally" "";
set "neg" "";

# ---- Positive signals: subject phrases ----

# Near-certain tells. +10 = instant trigger.
# "would you rate" covers "How would you rate the support you
# received?" (stock Zendesk CSAT subject) and every "how/where
# would you rate X" variant regardless of what X is.
if anyof (
  header :contains "subject" [
    "how did we do",
    "how are we doing",
    "tell us how we did",
    "how likely are you to recommend",
    "would you rate"
  ],
  header :matches "subject" [
    "*how*d we do*"
  ]
) {
  set "tally" "${tally}xxxxxxxxxx";
}

# Very strong. +8
if header :contains "subject" [
  "rate your",
  "rate us",
  "rate our",
  "please rate",
  "how satisfied",
  "leave a review",
  "leave us a review",
  "write a review",
  "leave your review",
  "take our survey",
  "take a quick survey",
  "take a short survey",
  "take this survey",
  "complete our survey",
  "review your recent",
  "how was your",
  "share your feedback",
  "give us your feedback",
  "your feedback is important"
] {
  set "tally" "${tally}xxxxxxxx";
}

# Strong. +7
if anyof (
  header :contains "subject" [
    "help us improve",
    "your feedback matters",
    "your opinion matters",
    "your opinion counts",
    "we would love your feedback",
    "we would love to hear",
    "love to hear from you",
    "was your issue resolved",
    "did we resolve"
  ],
  header :matches "subject" [
    "*we*d love your feedback*",
    "*we*d love to hear*"
  ]
) {
  set "tally" "${tally}xxxxxxx";
}

# Solid single keywords. +6
if header :contains "subject" [
  "feedback",
  "survey",
  "questionnaire",
  "satisfaction",
  "your opinion",
  "your input"
] {
  set "tally" "${tally}xxxxxx";
}

# Suggestive fragments. +5
if header :contains "subject" [
  "tell us",
  "what you think",
  "your thoughts",
  "we value your",
  "share your",
  "hear from you"
] {
  set "tally" "${tally}xxxxx";
}

# Post-experience thank-yous: the classic opener for review
# requests whose actual ask lives only in the body.
# Deliberately excludes "thank you for your order/purchase"
# (too transactional). +5
if header :contains "subject" [
  "thank you for joining",
  "thanks for joining",
  "thank you for visiting",
  "thanks for visiting",
  "thank you for attending",
  "thanks for attending",
  "thank you for coming",
  "thanks for coming",
  "thank you for dining",
  "thanks for dining",
  "thank you for staying",
  "thanks for staying",
  "thank you for stopping by",
  "thanks for stopping by",
  "thank you for your visit",
  "thanks for your visit"
] {
  set "tally" "${tally}xxxxx";
}

# Weak context words. +4
if header :contains "subject" [
  "your experience",
  "your visit",
  "your stay",
  "recommend us",
  "your rating",
  "star rating"
] {
  set "tally" "${tally}xxxx";
}

# "review"/"reviews" as a standalone word, approximated with
# wildcards: at the start, at the end, or between spaces.
# Misses punctuation-adjacent cases like "(review)", but
# excludes "preview", "reviewed", "reviewing". +3
if header :matches "subject" [
  "review",
  "reviews",
  "review *",
  "reviews *",
  "* review",
  "* reviews",
  "* review *",
  "* reviews *"
] {
  set "tally" "${tally}xxx";
}

# "takes 2 minutes", "30 seconds", "2-minute survey" etc.
# "?" matches exactly one character (not digit-specific,
# but close enough for a +2 signal). +2
if header :matches "subject" [
  "* ? minute*",
  "* ?? minute*",
  "* ?-minute*",
  "* ??-minute*",
  "* ? mins*",
  "* ?? mins*",
  "* ? seconds*",
  "* ?? seconds*"
] {
  set "tally" "${tally}xx";
}

# +2
if header :contains "subject" [
  "your recent"
] {
  set "tally" "${tally}xx";
}

# "What's next" follow-up hook, common in post-visit review
# asks. Wildcard covers straight/curly/missing apostrophes. +2
if header :matches "subject" [
  "*what*s next*"
] {
  set "tally" "${tally}xx";
}

# ---- Positive signals: sender ----

# Entire local part advertises the purpose. +8
if address :localpart :is "from" [
  "feedback",
  "survey",
  "surveys",
  "review",
  "reviews",
  "nps",
  "voc",
  "customerfeedback",
  "customer-feedback",
  "customervoice",
  "customer-voice"
] {
  set "tally" "${tally}xxxxxxxx";
}

# Survey and review platforms. +8
if address :domain :contains "from" [
  "qualtrics",
  "medallia",
  "surveymonkey",
  "momentive",
  "delighted",
  "trustpilot",
  "bazaarvoice",
  "getfeedback",
  "asknicely",
  "typeform",
  "alchemer",
  "surveygizmo",
  "birdeye",
  "podium",
  "yotpo",
  "feefo",
  "reviews.io",
  "judge.me",
  "stamped.io",
  "okendo"
] {
  set "tally" "${tally}xxxxxxxx";
}

# Mixed-purpose booking/experience platforms: these relay
# review asks AND legitimate booking confirmations from the
# same address, so they get half the weight of the pure
# review platforms above. A confirmation from one of these
# (+4 domain, +2 noreply, +2 unsubscribe = 8) stays under
# the threshold; a review-flavored subject pushes it over.
# occsn.com = Occasion (venue booking, sends as the venue's
# name from no-reply@occsn.com). +4
if address :domain :contains "from" [
  "occsn.com"
] {
  set "tally" "${tally}xxxx";
}

# Local part merely contains a purpose word (feedback-noreply@ etc.). +4
if address :localpart :contains "from" [
  "feedback",
  "survey"
] {
  set "tally" "${tally}xxxx";
}

# Automated senders. Weak on its own. +2
if address :localpart :contains "from" [
  "noreply",
  "no-reply",
  "donotreply",
  "do-not-reply"
] {
  set "tally" "${tally}xx";
}

# Bulk-mail marker: nearly all feedback requests carry this,
# nearly no personal mail does. +2
if exists "list-unsubscribe" {
  set "tally" "${tally}xx";
}

# ---- Soft negative signals: raise the threshold ----
if header :contains "subject" [
  "receipt",
  "invoice",
  "payment",
  "statement",
  "password",
  "verification",
  "security alert",
  "tracking",
  "order confirm",
  "shipping confirm",
  "your order has",
  "booking confirm",
  "is confirmed",
  "appointment",
  "reservation",
  "boarding pass",
  "itinerary",
  "renewal"
] {
  set "neg" "${neg}xxx";
}

# ---- Decision ----
set :length "score" "${tally}";
set :length "penalty" "${neg}";

if string :value "ge" :comparator "i;ascii-numeric" "${penalty}" "3" {
  if string :value "ge" :comparator "i;ascii-numeric" "${score}" "13" {
    fileinto "${folder}";
    stop;
  }
} elsif string :value "ge" :comparator "i;ascii-numeric" "${score}" "10" {
  fileinto "${folder}";
  stop;
}
