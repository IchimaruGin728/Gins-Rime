-- Gins-Rime Purified Logic Engine Entry Point
-- Generated for 100% rebranding and functional completeness

core = require('core/core')

-- ── Processors ───────────────────────────────────────────────
core.auto_phrase = require('core/auto_phrase')
core.input_statistics = require('core/input_statistics')
core.key_binder = require('core/key_binder')
core.partial_commit = require('core/partial_commit')
core.super_processor = require('core/super_processor')
core.super_tips = require('core/super_tips')
core.super_sequence = require('core/super_sequence')
core.user_predict = require('core/user_predict')

-- ── Translators ──────────────────────────────────────────────
core.number_translator = require('core/number_translator')
core.set_schema = require('core/set_schema')
core.shijian = require('core/shijian')
core.unicode = require('core/unicode')
core.version_display = require('core/version_display')

-- ── Filters ──────────────────────────────────────────────────
core.charset_filter = require('core/charset_filter')
core.super_calculator = require('core/super_calculator')
core.super_comment_preedit = require('core/super_comment_preedit')
core.super_english = require('core/super_english')
core.super_filter = require('core/super_filter')
core.super_lookup = require('core/super_lookup')
core.super_replacer = require('core/super_replacer')

-- Global exports for compatibility with legacy calls
auto_phrase = core.auto_phrase
input_statistics = core.input_statistics
key_binder = core.key_binder
partial_commit = core.partial_commit
super_processor = core.super_processor
super_tips = core.super_tips
super_sequence = core.super_sequence
user_predict = core.user_predict
number_translator = core.number_translator
set_schema = core.set_schema
shijian = core.shijian
unicode = core.unicode
version_display = core.version_display
charset_filter = core.charset_filter
super_calculator = core.super_calculator
super_comment_preedit = core.super_comment_preedit
super_english = core.super_english
super_filter = core.super_filter
super_lookup = core.super_lookup
super_replacer = core.super_replacer
