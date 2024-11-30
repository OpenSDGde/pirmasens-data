#!/usr/bin/env ruby
require 'yaml'
require 'fileutils'

# ===============================
# Konfiguration
# ===============================

# Pfad zur global_indicators.yml Datei
YAML_FILE = './translations/de/global_indicators.yml'

# Zielverzeichnis für die .md Dateien
OUTPUT_DIR = 'meta'

# Vordefinierte Strings
SOURCE_TYPE = 'Stadt Primasens' # Passe dies nach Bedarf an
NATIONAL_GEOGRAPHICAL_COVERAGE = 'Primasens' # Passe dies nach Bedarf an

# ===============================
# Funktionen
# ===============================

# Funktion zum Erstellen des indicator_sort_order
def generate_sort_order(main, sub)
  main_padded = main.to_i.to_s.rjust(2, '0')
  sub_padded = sub.to_i.to_s.rjust(2, '0')
  "01-#{main_padded}-#{sub_padded}" # Beispiel: "01-01-01"
end

# Funktion zum Erstellen des Inhalts der .md Datei
def generate_md_content(indicator_number, graph_title, sort_order, source_type, geographical_coverage)
  <<~MD
    ---
    # #{indicator_number}. Indikator-Nummer eingeben 
    sdg_goal: #{indicator_number.split('.').first} 
    indicator_number: #{indicator_number}
    graph_title: #{graph_title}
    indicator_sort_order: #{sort_order}
     
    # 2. Grafikart auswählen: 
    data_non_statistical: false  # set to 'false' for chart/graph visualization 
    graph_type: bar  # chart types include: bar, line, binary 
    #graph_stacked_disaggregation: Gruppe  ## uncomment this line for stacked bars. Replace 'Geschlecht' with the field of aggregation. 
    
    national_geographical_coverage: #{geographical_coverage}
    
    SOURCE_TYPE: #{source_type}
    
    language: de   
    published: true 
    reporting_status: complete
    ---
  MD
end

# ===============================
# Hauptprogramm
# ===============================

# Überprüfen, ob die YAML-Datei existiert
unless File.exist?(YAML_FILE)
  puts "Fehler: Die Datei #{YAML_FILE} wurde nicht gefunden."
  exit 1
end

# Laden der YAML-Datei
begin
  indicators = YAML.load_file(YAML_FILE)
rescue Psych::SyntaxError => e
  puts "Fehler beim Parsen der YAML-Datei: #{e.message}"
  exit 1
end

# Erstellen des Zielverzeichnisses, falls es nicht existiert
FileUtils.mkdir_p(OUTPUT_DIR)

# Iterieren über jede Indikatornummer und Maßnahme
indicators.each do |key, measure|
  # Erwartetes Format des Schlüssels: "1-1-title"
  if key =~ /^(\d+)-(\d+)-title$/
    main = Regexp.last_match(1)
    sub = Regexp.last_match(2)
    indicator_number = "#{main}.#{sub}"
    
    # Dateiname: "1-1.md"
    filename = "#{main}-#{sub}.md"
    filepath = File.join(OUTPUT_DIR, filename)
    
    # Graph Title: "global_indicators.1-1-title"
    graph_title = key
    
    # indicator_sort_order: "01-01-01" (Beispiel, passe nach Bedarf an)
    sort_order = generate_sort_order(main, sub)
    
    # Erstellen des Inhalts
    content = generate_md_content(indicator_number, graph_title, sort_order, SOURCE_TYPE, NATIONAL_GEOGRAPHICAL_COVERAGE)
    
    # Schreiben der .md Datei
    begin
      File.write(filepath, content)
      puts "Erstellt: #{filepath}"
    rescue StandardError => e
      puts "Fehler beim Schreiben der Datei #{filepath}: #{e.message}"
    end
  else
    puts "Warnung: Schlüssel '#{key}' entspricht nicht dem erwarteten Format 'x-y-title' und wurde übersprungen."
  end
end

puts "Alle .md Dateien wurden erfolgreich erstellt im Ordner '#{OUTPUT_DIR}'."

