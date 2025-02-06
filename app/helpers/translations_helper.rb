module TranslationsHelper
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
