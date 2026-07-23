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
# ==========================================================

# ---- Hard vetoes: never score these ----

# Genuine replies carry In-Reply-To. Bulk feedback mail never does.
if exists "in-reply-to" {
  return;
}

# Reply/forward subject prefixes. :matches anchors to the whole
# subject, so a mid-subject "re:" cannot trigger this.
if header :matches "subject" [
  "re:*",
  "re :*",
  "fw:*",
  "fw :*",
  "fwd:*",
  "fwd :*"
] {
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
if header :contains "subject" [
  "how did we do",
  "how are we doing",
  "how'd we do",
  "tell us how we did",
  "how likely are you to recommend"
] {
  set "tally" "${tally}xxxxxxxxxx";
}

# Very strong. +8
if header :contains "subject" [
  "rate your",
  "rate us",
  "rate our",
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
if header :contains "subject" [
  "help us improve",
  "your feedback matters",
  "your opinion matters",
  "your opinion counts",
  "we'd love your feedback",
  "we would love your feedback",
  "we'd love to hear",
  "we would love to hear",
  "love to hear from you"
] {
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
