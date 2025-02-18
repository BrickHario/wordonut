class TranslationsController < ApplicationController
  require "unidecode"
  require "concurrent"

  TARGET_LANGUAGES = %w[da nl en fo de is nb sv ca fr gl it pt-pt ro es mt ar bs bg hr mk sr-Latn sl sk cs pl ru uk lv lt sq hy az eu et fi ka el hu kmr tr cy ga].freeze
  TRANSLITERATION_LANGUAGES = %w[hy ka el mk ru uk bg ar].freeze
  LANGUAGE_NAMES = {
    "sq" => "Albanian", "ar" => "Arabic", "hy" => "Armenian", "az" => "Azerbaijani", "eu" => "Basque",
    "bs" => "Bosnian", "bg" => "Bulgarian", "ca" => "Catalan", "hr" => "Serbo-Croatian",
    "cs" => "Czech", "da" => "Danish", "nl" => "Dutch", "en" => "English",
    "et" => "Estonian", "fo" => "Faroese", "fi" => "Finnish", "fr" => "French",
    "gl" => "Galician", "ka" => "Georgian", "de" => "German", "el" => "Greek",
    "hu" => "Hungarian", "is" => "Icelandic", "ga" => "Irish", "it" => "Italian",
    "kmr" => "Kurdish", "lv" => "Latvian", "lt" => "Lithuanian", "mk" => "Macedonian",
    "mt" => "Maltese", "nb" => "Norwegian", "pl" => "Polish", "pt-pt" => "Portuguese",
    "ro" => "Romanian", "ru" => "Russian", "sr-Latn" => "Serbian", "sk" => "Slovak",
    "sl" => "Slovenian", "es" => "Spanish", "sv" => "Swedish", "tr" => "Turkish",
    "uk" => "Ukrainian", "cy" => "Welsh"
  }.freeze
  SIMILAR_LETTERS = {
    "v" => [ "w", "f" ], "w" => [ "v" ], "d" => [ "t", "ð" ], "t" => [ "d" ], "b" => [ "p" ],
    "p" => [ "b", "f" ], "f" => [ "v", "p" ], "s" => [ "z" ], "z" => [ "s" ],
    "c" => [ "k", "ċ" ], "k" => [ "c" ], "ä" => [ "a", "e" ], "ö" => [ "o" ],
    "ü" => [ "u" ], "u" => [ "ü" ], "y" => [ "i", "j", "í" ], "i" => [ "y", "j", "í" ],
    "j" => [ "i", "y", "í" ], "í" => [ "i" ], "ħ" => [ "h" ], "h" => [ "ħ" ], "ë" => [ "ă", "å" ],
    "ă" => [ "ë", "å" ], "ċ" => [ "c" ], "ð" => [ "d" ], "å" => [ "ë", "ă" ], "m"  => [ "n", "ñ" ], "n"  => [ "m", "ñ" ], "ñ"  => [ "m", "n" ], "l"  => [ "r", "ł" ],
  "r"  => [ "l", "ʀ" ], "q"  => [ "k", "c" ], "æ"  => [ "a", "e" ], "œ"  => [ "o", "e" ],
  "ß"  => [ "ss" ], "á"  => [ "a" ], "à"  => [ "a" ], "â"  => [ "a" ], "ã"  => [ "a" ],
  "é"  => [ "e" ], "è"  => [ "e" ], "ê"  => [ "e" ], "ì"  => [ "i" ], "î"  => [ "i" ],
  "ï"  => [ "i" ], "ó"  => [ "o" ], "ò"  => [ "o" ], "ô"  => [ "o" ], "õ"  => [ "o" ],
  "ú"  => [ "u" ], "ù"  => [ "u" ], "û"  => [ "u" ], "ý"  => [ "y" ], "ÿ"  => [ "y" ],
  "č"  => [ "c", "ch" ], "ć"  => [ "c" ], "đ"  => [ "d" ], "š"  => [ "s" ], "ž"  => [ "z" ],
  "ł"  => [ "l" ], "ř"  => [ "r" ], "ť"  => [ "t" ], "ů"  => [ "u" ], "ő"  => [ "o" ],
  "ű"  => [ "u" ], "ğ"  => [ "g" ], "ı"  => [ "i" ], "ş"  => [ "s" ], "ď"  => [ "d" ],
  "ň"  => [ "n" ], "ŕ"  => [ "r" ], "ľ"  => [ "l" ], "ą"  => [ "a" ], "ę"  => [ "e" ],
  "ġ"  => [ "g" ], "ĳ"  => [ "i", "j" ]
  }.freeze

  def new
    if params[:text].present? && params[:source_lang].present?
      session[:last_searched_word] = params[:text]
      session[:last_searched_lang] = params[:source_lang]
      session[:normalized_source] ||= params[:source_lang].to_s.strip.downcase
    end

    if session[:last_searched_word].present? && session[:last_searched_lang].present?
      @source_language_name = LANGUAGE_NAMES[session[:last_searched_lang]]
      @translations = translate_text(
        session[:last_searched_word],
        session[:last_searched_lang],
        TARGET_LANGUAGES.reject { |lang| lang == session[:last_searched_lang] }
      )
      @word_data = fetch_word_data(session[:last_searched_word], @source_language_name)

      english_word = if session[:last_searched_lang] == "en"
                       session[:last_searched_word]
      else
                       (@translations["en"] && @translations["en"][:original]) || session[:last_searched_word]
      end

      @translated_synonyms = fetch_synonyms(english_word)
    else
      @translations = {}
      @word_data = {}
      @translated_synonyms = []
    end

    render :main
  end

  skip_before_action :verify_authenticity_token, only: [ :create ]

  def create
    text = params[:text].to_s.strip
    source_lang = params[:source_lang].to_s.strip
  
    # Basis-Validierung
    if text.blank? || source_lang.blank?
      session[:last_searched_word] = nil
      session[:last_searched_lang] = nil
      redirect_to root_path, notice: "Select a language." and return
    end
  
    if text.count(" ") > 2
      session[:last_searched_word] = nil
      session[:last_searched_lang] = nil
      redirect_to root_path, notice: "Type single words only." and return
    end
  
    if text.length > 20
      session[:last_searched_word] = nil
      session[:last_searched_lang] = nil
      redirect_to root_path, notice: "20 characters: Max. length" and return
    end
  
    session[:last_searched_word] = text
    session[:last_searched_lang] = source_lang
  
    # Übersetzungen und Word-Daten ermitteln
    target_langs = TARGET_LANGUAGES.reject { |lang| lang == source_lang }
    @source_language_name = LANGUAGE_NAMES[source_lang]
    @translations = translate_text(text, source_lang, target_langs)
    @word_data = fetch_word_data(text, @source_language_name)
    
    english_word = if source_lang == "en"
                     text
                   else
                     (@translations["en"] && @translations["en"][:original]) || text
                   end
    @translated_synonyms = fetch_synonyms(english_word)
  
    # Falls weder Synonyme noch (Etymologie und Bedeutung) gefunden wurden
    if @translated_synonyms.blank? && (@word_data.nil? || (@word_data[:etymology].blank? && @word_data[:meaning].blank?))
      session[:last_searched_word] = nil
      session[:last_searched_lang] = nil
      redirect_to root_path, notice: "Word not found." and return
    end
  
    @word_array = split_word_to_array(text)
    @colors = {}
  
    TARGET_LANGUAGES.each do |lang|
      @colors[lang] = similarity_color(@translations.dig(lang, :similarity), lang, source_lang)
    end
  
    render :main
  end
  


  def translate_with_azure(text, source_lang, target_lang, retries = 3)
    text = text.include?("/") ? text.split("/").first.strip : text.strip
    url = "#{ENV['AZURE_ENDPOINT']}/translate?api-version=3.0&from=#{source_lang}&to=#{target_lang}"
    headers = {
      "Ocp-Apim-Subscription-Key" => ENV["AZURE_API_KEY"],
      "Content-Type" => "application/json",
      "Ocp-Apim-Subscription-Region" => "westeurope"
    }
    body = [ { "Text" => text } ].to_json

    attempts = 0
    begin
      response = HTTParty.post(url, headers: headers, body: body, timeout: 10)
      result = response.parsed_response
      translated_text = result.first["translations"].first["text"]
      translated_text.include?("/") ? translated_text.split("/").first.strip : translated_text.strip
    rescue => e
      attempts += 1
      if attempts < retries
        sleep(1)
        retry
      else
        Rails.logger.error("Azure-Übersetzungsfehler für #{target_lang}: #{e.message}")
        nil
      end
    end
  end

  def translate_text(text, source_lang, target_langs)
    # Nur umwandeln, wenn die Source-Sprache nicht lateinisch ist:
    input_transliterated = if TRANSLITERATION_LANGUAGES.include?(source_lang)
                             Unidecoder.decode(text)
                           else
                             text
                           end
  
    promises = target_langs.map do |lang|
      Concurrent::Promise.execute do
        begin
          translation = translate_with_azure(text, source_lang, lang)
          raise "Failed translation: #{lang}" if translation.nil?
  
          if TRANSLITERATION_LANGUAGES.include?(lang)
            # Für target Sprachen, die nicht lateinisch sind, benutze deine spezielle Transliteration:
            transliterated = transliterate(translation, lang)
            translation_transliterated = transliterated[:transliterated]
            similarity = calculate_similarity(input_transliterated, translation_transliterated)
            { lang => { original: transliterated[:original],
                        transliterated: translation_transliterated,
                        splited: split_word_to_array(translation),
                        similarity: (similarity * 100).to_i } }
                      else
                        # Für target-Sprachen, die lateinisch sind,
                        # sollen beide Seiten in lateinischer Form vorliegen.
                        translation_transliterated = if TRANSLITERATION_LANGUAGES.include?(lang)
                                                         Unidecoder.decode(translation)
                                                       else
                                                         translation
                                                       end
                        similarity = calculate_similarity(input_transliterated, translation_transliterated)
                        { lang => { original: translation,
                                    transliterated: translation_transliterated,
                                    splited: split_word_to_array(translation),
                                    similarity: (similarity * 100).to_i } }
                      end
                      
  
        rescue => e
          Rails.logger.error("Failed translation for #{lang}: #{e.message}.")
          { lang => { error: e.message } }
        end
      end
    end
  
    results = promises.map(&:value)
  
    failed_languages = results.select { |r| r.values.first[:error] }.map(&:keys).flatten
    if failed_languages.any?
      failed_languages.each do |lang|
        retry_translation = translate_with_azure(text, source_lang, lang)
        if retry_translation
          translation_transliterated = if TRANSLITERATION_LANGUAGES.include?(source_lang)
                                          Unidecoder.decode(retry_translation)
                                        else
                                          retry_translation
                                        end
          similarity = calculate_similarity(input_transliterated, translation_transliterated)
          results << { lang => { original: retry_translation,
                                  transliterated: translation_transliterated,
                                  splited: split_word_to_array(retry_translation),
                                  similarity: (similarity * 100).to_i } }
        end
      end
    end
  
    results.reduce({}, :merge)
  end
  
  

  def fetch_synonyms(word)
    require "cgi"
    api_url = "https://api.datamuse.com/words?rel_syn=#{CGI.escape(word)}"
    uri = URI(api_url)
    response = Net::HTTP.get(uri)
    json_response = JSON.parse(response)
    json_response.map { |item| item["word"] }.take(5)
  rescue StandardError => e
    Rails.logger.error("Fehler beim Abrufen der Synonyme: #{e.message}")
    []
  end

  def transliterate(text, lang)
    case lang
    when "hy", "ka", "el", "mk", "ru", "uk", "bg", "ar"
      {
        original: text,
        transliterated: Unidecoder.decode(text)
      }
    else
      text
    end
  end

  def fetch_word_data(word, source_language_name)
    result = try_fetch_word_data(word, source_language_name)

    if result[:language_section].to_s.strip.empty? && word.present?
      # uppercase version
      alternate_word1 = word[0].upcase + word[1..-1]
      result_alt1 = try_fetch_word_data(alternate_word1, source_language_name)

      # downcase version
      alternate_word2 = word[0].downcase + word[1..-1]
      result_alt2 = try_fetch_word_data(alternate_word2, source_language_name)

      # nimm zweite wenn keine gibt
      result = result_alt1 unless result_alt1[:language_section].to_s.strip.empty?
      result = result_alt2 unless result_alt2[:language_section].to_s.strip.empty?
    end

    result
  end

  def try_fetch_word_data(word, source_language_name)
    api_url = "https://en.wiktionary.org/w/api.php"
    uri = URI(api_url)
    params = {
      action: "query",
      titles: word,
      prop: "extracts",
      explaintext: true,
      format: "json"
    }
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get(uri)
    json_response = JSON.parse(response)

    page = json_response.dig("query", "pages").values.first
    extract = page["extract"]

    language_section = extract_language_section(extract, source_language_name)
    verb_section = extract_verb_section(language_section)
    etymology = extract_etymology(language_section)
    puts language_section

    {
      title: page["title"],
      etymology: etymology,
      language_section: language_section,
      verb_section: verb_section,
      full: extract
    }
  end


  def extract_language_section(text, source_language_name)
    return "" unless text
    match = text.match(/^==\s*#{Regexp.escape(source_language_name)}\s*==$\n+(.*?)(?=\n== |\z)/m)
    match ? match[1].strip : ""
  end
  

  def extract_verb_section(language_section)
    return "" unless language_section
    match = language_section.match(/=== Adjective ===\s*([\s\S]*?)(?=\n==|\z)/) ||
            language_section.match(/=== Noun ===\s*([\s\S]*?)(?=\n==|\z)/) ||
            language_section.match(/=== Adverb ===\s*([\s\S]*?)(?=\n==|\z)/) ||
            language_section.match(/=== Verb ===\s*([\s\S]*?)(?=\n==|\z)/)

    if match
      lines = match[1].strip.split("\n")
      lines.shift if lines.size > 1 # Entfernt erste Zeile
      limited_lines = lines.first(10) # Max. 10 Zeilen
      limited_lines.join("\n").strip
    end
  end

  def extract_etymology(language_section)
    return "" unless language_section
    match = language_section.match(/=== Etymology ===\s*([\s\S]*?)(?=\n==|\z)/) ||
            language_section.match(/=== Etymology 1 ===\s*([\s\S]*?)(?=\n==|\z)/)
    match ? match[1].strip : ""
  end

  def split_word_to_array(word)
    return [] unless word.is_a?(String)
    word.strip.downcase.split("")
  end

  def calculate_similarity(word1, word2)
    array1 = split_word_to_array(word1)
    array2 = split_word_to_array(word2)

    max_length = [ array1.length, array2.length ].max
    difference = 0.0

    max_length.times do |i|
      char1 = array1[i] || ""
      char2 = array2[i] || ""

      if char1 != char2
        similar_match = SIMILAR_LETTERS[char1]&.include?(char2) || SIMILAR_LETTERS[char2]&.include?(char1)
        if similar_match
          difference += 0.5
        else
          has_match = (i > 0 && (array1[i - 1] == array2[i] || SIMILAR_LETTERS[array1[i - 1]]&.include?(array2[i]))) ||
                      (i + 1 < max_length && (array1[i + 1] == array2[i] || SIMILAR_LETTERS[array1[i + 1]]&.include?(array2[i])))
          difference += has_match ? 0.5 : 1
        end
      end
    end
    penalty_shortwords = array1 == array2 ? 1.0 : { 2 => 0.8, 3 => 0.9, 4 => 0.95 }.fetch(array2.length, 1.0)
    same_cap = array1 == array2 ? 1 : (array1[0] == array2[0] || array1[0] == array2[1]) ? 1.02 : 0.8

    ((1 - (difference.to_f / max_length)) * penalty_shortwords) * same_cap
  end
  def similarity_color(similarity, lang, source_lang)
    normalized_lang = lang.to_s.strip.downcase
    normalized_source = source_lang.to_s.strip.downcase
    return "#0D1A0A" if normalized_lang == normalized_source  # schwarz

    case similarity
    when 0..10
      "#D10F14" # rot
    when 11..30
      "#F9875C" # hellrot
    when 31..60
      "#B6D64F" # hellgrün
    when 61..85
      "#0DBC06" # grün
    when 86..100
      "#004D00" # dunkelgrün
    else
      "#8E8E8E" # grau
    end
  end
end
