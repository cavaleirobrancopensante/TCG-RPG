class_name I18n
extends RefCounted
## Languages: English (the text in the code and data), Brazilian Portuguese and Spanish.
## Translations live in data/i18n/pt.json and es.json as {English: translation}. They are loaded
## into Godot's TranslationServer, so labels and buttons translate themselves; everything that
## is formatted or drawn by hand goes through I18n.t().

const LANGS: Array[String] = ["en", "pt", "es"]
const LOCALES := {"en": "en", "pt": "pt_BR", "es": "es"}
const NAMES := {"en": "English", "pt": "Português", "es": "Español"}

static var lang := "en"
static var _loaded := false


static func setup(p_lang: String) -> void:
	if not _loaded:
		_loaded = true
		for code in ["pt", "es"]:
			var path := "res://data/i18n/%s.json" % code
			var table = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
			if typeof(table) != TYPE_DICTIONARY:
				push_warning("I18n: missing or unreadable " + path)
				continue
			var tr := Translation.new()
			tr.locale = LOCALES[code]
			for k in table:
				if String(table[k]) != "":
					tr.add_message(k, table[k])
			TranslationServer.add_translation(tr)
	lang = p_lang if LANGS.has(p_lang) else "en"
	TranslationServer.set_locale(LOCALES[lang])


## Translate a string (works anywhere, including static functions and drawing code).
static func t(s: String) -> String:
	if s == "" or lang == "en":
		return s
	return str(TranslationServer.translate(s))


## Translate a format string, then fill it in: I18n.f("%d gold", [n]).
static func f(s: String, args) -> String:
	return t(s) % args


## A card's type line, e.g. "Criatura — Clérigo Humano".
static func type_line(card: Dictionary) -> String:
	var tl := t(String(card.get("type", "")).capitalize())
	if card.get("subtype", "") != "":
		tl += " · " + t(card["subtype"])
	return tl


## A translated copy of a card's visible text (name, rules, flavour).
static func card_text(card: Dictionary, field: String) -> String:
	return t(String(card.get(field, "")))
