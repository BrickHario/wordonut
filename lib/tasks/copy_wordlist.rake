namespace :assets do
    desc "Copy compiled src/layout/wordlist.css to public/css/layout/wordlist.css"
    task copy_wordlist: :environment do
      # Suche nach der kompilierten Datei (mit Fingerprint) im Ordner public/assets/src/layout
      compiled_file = Dir.glob(Rails.root.join("public", "assets", "src", "layout", "wordlist-*.css")).first

      if compiled_file && File.exist?(compiled_file)
        destination_dir = Rails.root.join("public", "css", "layout")
        FileUtils.mkdir_p(destination_dir)
        destination_file = destination_dir.join("wordlist.css")
        FileUtils.cp(compiled_file, destination_file)
        puts "Copied #{compiled_file} to #{destination_file}"
      else
        puts "Compiled src/layout/wordlist.css not found in public/assets!"
      end
    end
  end
