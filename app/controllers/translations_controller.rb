class TranslationsController < ApplicationController
  require 'unidecode'
  require 'concurrent'

  TARGET_LANGUAGES = %w[da nl en fo de is nb sv ca fr gl it pt-pt ro es mt ar bs bg hr mk sr-Latn sl sk cs pl ru uk lv lt sq hy az eu et fi ka el hu kmr tr cy ga].freeze
  TRANSLITERATION_LANGUAGES = %w[hy ka el mk ru uk bg ar].freeze
  LANGUAGE_NAMES = {'sq' => 'Albanian', 'hy' => 'Armenian', 'az' => 'Azerbaijani', 'eu' => 'Basque', 'bs' => 'Bosnian', 'bg' => 'Bulgarian', 'ca' => 'Catalan', 'hr' => 'Serbo-Croatian', 'cs' => 'Czech', 'da' => 'Danish', 'nl' => 'Dutch', 'en' => 'English', 'et' => 'Estonian', 'fo' => 'Faroese', 'fi' => 'Finnish', 'fr' => 'French', 'gl' => 'Galician', 'ka' => 'Georgian', 'de' => 'German', 'el' => 'Greek', 'hu' => 'Hungarian', 'is' => 'Icelandic', 'ga' => 'Irish', 'it' => 'Italian', 'kmr' => 'Kurdish', 'lv' => 'Latvian', 'lt' => 'Lithuanian', 'mk' => 'Macedonian', 'mt' => 'Maltese', 'nb' => 'Norwegian', 'pl' => 'Polish', 'pt-pt' => 'Portuguese', 'ro' => 'Romanian', 'ru' => 'Russian', 'sr-Latn' => 'Serbian', 'sk' => 'Slovak', 'sl' => 'Slovenian', 'es' => 'Spanish', 'sv' => 'Swedish', 'tr' => 'Turkish', 'uk' => 'Ukrainian', 'cy' => 'Welsh', 'ar' => 'Arabic'}.freeze
  SIMILAR_LETTERS = { 'v' => ['w', 'f'], 'w' => ['v'], 'd' => ['t'], 't' => ['d'], 'b' => ['p'], 'p' => ['b', 'f'], 'f' => ['v', 'p'], 's' => ['z'], 'z' => ['s'], 'c' => ['k', 'ċ'], 'k' => ['c'], 'ä' => ['a', 'e'], 'ö' => ['o'], 'ü' => ['u'], 'u' => ['ü'], 'y' => ['i'], 'i' => ['y', 'j', 'í'], 'j' => ['i'], 'í' => ['i'], 'ħ' => ['h'], 'h' => ['ħ'], 'ë' => ['ă'], 'ă' => ['ë'], 'ċ' => ['c'] }.freeze

  def new
    if params[:text].present? && params[:source_lang].present?
      session[:last_searched_word] = params[:text]
      session[:last_searched_lang] = params[:source_lang]
    end
  
    if session[:last_searched_word].present? && session[:last_searched_lang].present?
      @source_language_name = LANGUAGE_NAMES[session[:last_searched_lang]]
      @translations = translate_text(session[:last_searched_word], session[:last_searched_lang], TARGET_LANGUAGES.reject { |lang| lang == session[:last_searched_lang] })
      @word_data = fetch_word_data(session[:last_searched_word], @source_language_name)
      @translated_synonyms = @word_data[:synonyms] || []
    else
      @translations = {}
      @word_data = {}
      @translated_synonyms = []
    end
  
    render :main
  end

  skip_before_action :verify_authenticity_token, only: [:create]

  def create
    text = params[:text].to_s.strip
    source_lang = params[:source_lang].to_s.strip
  
    if text.blank? || source_lang.blank?
      flash[:alert] = "Type a word and select a language."
      redirect_to root_path and return
    end
  
    if text.length > 20
      flash[:alert] = "The word must not exceed 20 characters."
      redirect_to root_path and return
    end
  
    session[:last_searched_word] = text
    session[:last_searched_lang] = source_lang
  
    target_langs = TARGET_LANGUAGES.reject { |lang| lang == source_lang }
  
    @source_language_name = LANGUAGE_NAMES[source_lang]
    @translations = translate_text(text, source_lang, target_langs)
    @word_data = fetch_word_data(text, @source_language_name)
    @word_array = split_word_to_array(text)
    @colors = {}
  
    TARGET_LANGUAGES.each do |lang|
      @colors[lang] = similarity_color(@translations.dig(lang, :similarity), lang, source_lang)
    end
  
    render :main
  end
  
  
  private

  def translate_with_azure(text, source_lang, target_lang, retries = 3)
    text = text.include?('/') ? text.split('/').first.strip : text.strip
    url = "#{ENV['AZURE_ENDPOINT']}/translate?api-version=3.0&from=#{source_lang}&to=#{target_lang}"
    headers = {
      "Ocp-Apim-Subscription-Key" => ENV['AZURE_API_KEY'],
      "Content-Type" => "application/json",
      "Ocp-Apim-Subscription-Region" => "westeurope"
    }
    body = [{ "Text" => text }].to_json
  
    attempts = 0
    begin
      response = HTTParty.post(url, headers: headers, body: body, timeout: 10)
      result = response.parsed_response
  
      translated_text = result.first["translations"].first["text"]
      return translated_text.include?('/') ? translated_text.split('/').first.strip : translated_text.strip
    rescue => e
      attempts += 1
      if attempts < retries
        sleep(1)
        retry
      else
        Rails.logger.error("Azure-Übersetzungsfehler für #{target_lang}: #{e.message}")
        return nil
      end
    end
  end
  
  
  def translate_text(text, source_lang, target_langs)
    promises = target_langs.map do |lang|
      Concurrent::Promise.execute do
        begin
          translation = translate_with_azure(text, source_lang, lang)
          if translation.nil?
            raise "Failed translation: #{lang}"
          end
  
          if TRANSLITERATION_LANGUAGES.include?(lang)
            transliterated = transliterate(translation, lang)
            similarity = calculate_similarity(text, transliterated[:transliterated])
            { lang => { original: transliterated[:original], transliterated: transliterated[:transliterated], splited: split_word_to_array(translation), similarity: (similarity * 100).to_i } }
          else
            similarity = calculate_similarity(text, translation)
            { lang => { original: translation, transliterated: translation, splited: split_word_to_array(translation), similarity: (similarity * 100).to_i } }
          end
        rescue => e
          Rails.logger.error("Failed translation for #{lang}: #{e.message}")
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
          results << { lang => { original: retry_translation, transliterated: retry_translation, splited: split_word_to_array(retry_translation), similarity: (calculate_similarity(text, retry_translation) * 100).to_i } }
        end
      end
    end
  
    results.reduce({}, :merge)
  end
  
  

  def fetch_synonyms(word)
    require 'cgi'
  
    api_url = "https://api.datamuse.com/words?rel_syn=#{CGI.escape(word)}"
    uri = URI(api_url)
    response = Net::HTTP.get(uri)
  
    json_response = JSON.parse(response)
    json_response.map { |item| item['word'] }.take(5)
  end

  def transliterate(text, lang)
    case lang
    when 'hy', 'ka', 'el', 'mk', 'ru', 'uk', 'bg', 'ar'
      {
        original: text,
        transliterated: Unidecoder.decode(text)
      }
    else
      text
    end
  end

  def fetch_word_data(word, source_language_name)
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
    {
      title: page["title"],
      etymology: etymology,
      language_section: language_section,
      verb_section: verb_section
    }
  end
  
  def extract_language_section(text, source_language_name)
    return "" unless text
    match = text.match(/^==\s*#{Regexp.escape(source_language_name)}\s*==$\n+(.*)/m)
    match ? match[1].strip : ""
  end
  
  def extract_verb_section(language_section)
    return "" unless language_section
    match = language_section.match(/=== Adjective ===\s*([\s\S]*?)(?=\n==|\z)/) || language_section.match(/=== Noun ===\s*([\s\S]*?)(?=\n==|\z)/) || language_section.match(/=== Verb ===\s*([\s\S]*?)(?=\n==|\z)/)
    
    if match
      lines = match[1].strip.split("\n")
      lines.shift if lines.size > 1 # Entfernt erste Zeile
      limited_lines = lines.first(10) # Begrenzt Anzahl Zeilen max. 10
      processed_text = limited_lines.join("\n").strip
      return processed_text
    end
  end
  
def extract_etymology(language_section)
    return "" unless language_section
    match = language_section.match(/=== Etymology ===\s*([\s\S]*?)(?=\n==|\z)/) || language_section.match(/=== Etymology 1 ===\s*([\s\S]*?)(?=\n==|\z)/)
    match ? match[1].strip : ""
  end
end

def split_word_to_array(word)
  return [] unless word.is_a?(String)
  word.strip.downcase.split("")
  end

def calculate_similarity(word1, word2)
  array1 = split_word_to_array(word1)
  array2 = split_word_to_array(word2)

  max_length = [array1.length, array2.length].max
  
  difference = 0.0

  max_length.times do |i|
    char1 = array1[i] || ""
    char2 = array2[i] || ""

    if char1 != char2
      similar_match = TranslationsController::SIMILAR_LETTERS[char1]&.include?(char2) || TranslationsController::SIMILAR_LETTERS[char2]&.include?(char1)
      if similar_match
        difference += 0.5
      else
      has_match = (i > 0 && (array1[i - 1] == array2[i] || TranslationsController::SIMILAR_LETTERS[array1[i - 1]]&.include?(array2[i]))) ||
            (i + 1 < max_length && (array1[i + 1] == array2[i] || TranslationsController::SIMILAR_LETTERS[array1[i + 1]]&.include?(array2[i])))
      difference += has_match ? 0.5 : 1
      end
    end
  end
  penalty_shortwords = array1 == array2 ? 1.0 : { 2 => 0.8, 3 => 0.9, 4 => 0.95 }.fetch(array2.length, 1.0)
  same_cap = array1 == array2 ? 1 : (array1[0] || "")[0] == (array2[0] || "")[0] ? 1.1 : 0.9
  ((1 - (difference.to_f / max_length)) * penalty_shortwords) * same_cap
end

def similarity_color(similarity, lang, source_lang)
  return "#0D1A0A" if lang == source_lang # black
  case similarity
  when 0..10
    "#D10F14" # red
  when 11..30
    "#F9875C" # light-red
  when 31..60
    "#B6D64F" # light-green
  when 61..85
    "#0DBC06" # green
  when 86..100
    "#004D00" # dark-green
  else
    "#8E8E8E" # grey
  end
end


