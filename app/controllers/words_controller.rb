class WordsController < ApplicationController
    before_action :require_login
  
    def wordlist
      @saved_words = current_user.liked_words
  
      case params[:sort]
      when "asc"
        @saved_words = @saved_words.order(:word)
      when "desc"
        @saved_words = @saved_words.order(word: :desc)
      when "default"
        @saved_words = current_user.liked_words
      end
    end
  
    def save
      word = params[:word]
      source_lang = params[:source_lang]
  
      if word.blank? || source_lang.blank?
        redirect_to root_path
        return
      end
  
      unless current_user.liked_words.exists?(word: word, source_lang: source_lang)
        current_user.liked_words.create(word: word, source_lang: source_lang)
        redirect_to root_path
      else
        redirect_to root_path
      end
    end
  
    def destroy
      liked_word = current_user.liked_words.find(params[:id])
      liked_word.destroy
      redirect_to saved_words_path
    end

      def shared
        @liked_word = LikedWord.find_by(share_token: params[:token])
    
        if @liked_word
          redirect_to root_path(text: @liked_word.word, source_lang: @liked_word.source_lang)
        else
          redirect_to root_path
        end
      end
  end
  